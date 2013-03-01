require 'fileutils'
require 'pathname'
require 'tmpdir'

require 'aruba/cucumber'
require 'wrong'

World(Wrong)

ENV['FIXTURES_DIR'] = Pathname.new(__FILE__).
  dirname.join('..', 'fixtures').realpath.to_s

# https://github.com/cucumber/aruba/pull/144
After do
  processes.clear
end

Before do
  @aruba_timeout_seconds = 5
end
