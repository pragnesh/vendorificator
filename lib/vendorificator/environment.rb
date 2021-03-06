require 'pathname'

require 'minigit'

require 'vendorificator/config'

module Vendorificator
  class Environment
    attr_reader :config
    attr_accessor :shell, :vendor_instances

    def initialize(vendorfile=nil)
      @vendor_instances = []

      @config = Vendorificator::Config.new
      @config.environment = self
      @config.read_file(find_vendorfile(vendorfile).to_s)

      self.each_vendor_instance{ |mod| mod.compute_dependencies! }
    end

    def say_status(*args)
      shell.say_status(*args) if shell
    end

    # Main MiniGit instance
    def git
      @git ||= MiniGit::new(config[:vendorfile_path])
    end

    # Git helpers
    def remotes
      @remotes ||= git.capturing.remote.lines.map(&:strip)
    end

    def current_branch
      git.capturing.rev_parse({:abbrev_ref => true}, 'HEAD').strip
    end

    def fast_forwardable?(to, from)
      git.capturing.merge_base(to, from).strip == from
    end

    # Public: Pulls all the remotes specified in options[:remote] or the config.
    #
    # options - The Hash of options.
    #
    # Returns nothing.
    def pull_all(options = {})
      ensure_clean!
      remotes = options[:remote] ? options[:remote].split(',') : config[:remotes]
      remotes.each do |remote|
        indent 'remote', remote do
          pull(remote, options)
        end
      end
    end

    # Public: Pulls a single remote and updates the branches.
    #
    # options - The Hash of options.
    #
    # Returns nothing.
    def pull(remote, options={})
      raise RuntimeError, "Unknown remote #{remote}" unless remotes.include?(remote)

      git.fetch(remote)
      git.fetch({:tags => true}, remote)

      ref_rx = /^refs\/remotes\/#{Regexp.quote(remote)}\//
      remote_branches = Hash[ git.capturing.show_ref.
        lines.
        map(&:split).
        map { |sha, name| name =~ ref_rx ? [$', sha] : nil }.
        compact ]

      each_vendor_instance do |mod|
        ours = mod.head
        theirs = remote_branches[mod.branch_name]
        if theirs
          if not ours
            say_status 'new', mod.branch_name, :yellow
            git.branch({:track => true}, mod.branch_name, theirs) unless options[:dry_run]
          elsif ours == theirs
            say_status 'unchanged', mod.branch_name
          elsif fast_forwardable?(theirs, ours)
            say_status 'updated', mod.name, :yellow
            mod.in_branch { git.merge({:ff_only => true}, theirs) } unless options[:dry_run]
          elsif fast_forwardable?(ours, theirs)
            say_status 'older', mod.branch_name
          else
            say_status 'complicated', mod.branch_name, :red
          end
        else
          say_status 'unknown', mod.branch_name
        end
      end
    end

    # Public: Push changes on module branches.
    #
    # options - The Hash containing options
    #
    # Returns nothing.
    def push(options = {})
      ensure_clean!

      pushable = []
      each_vendor_instance{ |mod| pushable += mod.pushable_refs }

      remotes = options[:remote] ? options[:remote].split(',') : config[:remotes]
      remotes.each{ |remote| git.push remote, pushable }

      git.push :tags => true
    end

    # Public: Runs all the vendor modules.
    #
    # options - The Hash of options.
    #
    # Returns nothing.
    def sync(options = {})
      ensure_clean!
      config[:use_upstream_version] = options[:update]

      each_vendor_instance(*options[:modules]) do |mod|
        say_status :module, mod.name
        indent do
          mod.run!
        end
      end
    end

    # Public: Goes through all the Vendor instances and runs the block
    #
    # modules - ?
    #
    # Returns nothing.
    def each_vendor_instance(*modules)
      modpaths = modules.map { |m| File.expand_path(m) }

      # We don't use @vendor_instances.each here, because Vendor#run! is
      # explicitly allowed to append to instantiate new dependencies, and #each
      # fails to catch up on some Ruby implementations.
      i = 0
      while true
        break if i >= @vendor_instances.length
        mod = @vendor_instances[i]
        yield mod if modules.empty? ||
          modules.include?(mod.name) ||
          modpaths.include?(mod.work_dir)
        i += 1
      end
    end

    # Public: Checks if the repository is clean.
    #
    # Returns boolean answer to the question.
    def clean?
      # copy code from http://stackoverflow.com/a/3879077/16390
      git.update_index '-q', '--ignore-submodules', '--refresh'
      git.diff_files '--quiet', '--ignore-submodules', '--'
      git.diff_index '--cached', '--quiet', 'HEAD', '--ignore-submodules', '--'
      true
    rescue MiniGit::GitError
      false
    end

    private

    # Private: Finds the vendorfile to use.
    #
    # given - the optional String containing vendorfile path.
    #
    # Returns a String containing the vendorfile path.
    def find_vendorfile(given=nil)
      given = [ given, ENV['VENDORFILE'] ].find do |candidate|
        candidate && !(candidate.respond_to?(:empty?) && candidate.empty?)
      end
      return given if given

      Pathname.pwd.ascend do |dir|
        vf = dir.join('Vendorfile')
        return vf if vf.exist?

        vf = dir.join('config/vendor.rb')
        return vf if vf.exist?

        # avoid stepping above the tmp directory when testing
        if ENV['VENDORIFICATOR_SPEC_RUN'] &&
            dir.join('vendorificator.gemspec').exist?
          raise ArgumentError, "Vendorfile not found"
        end
      end

      raise ArgumentError, "Vendorfile not found"
    end

    # Private: Aborts on a dirty repository.
    #
    # Returns nothing.
    def ensure_clean!
      raise DirtyRepoError unless clean?
    end

    # Private: Indents the output.
    #
    # Returns nothing.
    def indent(*args, &block)
      say_status *args unless args.empty?
      shell.padding += 1 if shell
      yield
    ensure
      shell.padding -= 1 if shell
    end

  end
end
