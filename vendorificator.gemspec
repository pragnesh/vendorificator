# -*- encoding: utf-8 -*-
require File.expand_path('../lib/vendorificator/version', __FILE__)
require 'minigit'

version = MiniGit::Capturing.
  describe( :match => 'v[0-9]*.[0-9]*.[0-9]*',
            :dirty => '.wip' ).
  strip.sub(/^v/, '').gsub('-', '.')

unless version.start_with?(Vendorificator::VERSION)
  raise ValueError, "Declared version is #{Vendorificator::VERSION.inspect}, but Git description is #{version.inspect}"
end

Gem::Specification.new do |gem|
  gem.authors       = ["Maciej Pasternacki"]
  gem.email         = ["maciej@pasternacki.net"]
  gem.description   = "Vendor everything. Stay sane."
  gem.summary       = "Integrate third-party vendor modules into your git repository"
  gem.homepage      = "https://github.com/3ofcoins/vendorificator/"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "vendorificator"
  gem.require_paths = ["lib"]
  gem.version       = version

  gem.add_dependency 'escape'
  gem.add_dependency 'thor', '>= 0.17.0'
  gem.add_dependency 'mixlib-config'
  gem.add_dependency 'minigit', '>= 0.0.3'

  gem.add_development_dependency 'aruba'
  gem.add_development_dependency 'cucumber'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'chef', '>= 10.16.0' unless defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
  gem.add_development_dependency 'vcr'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'wrong', '>= 0.7.0'
  gem.add_development_dependency 'rake'
end
