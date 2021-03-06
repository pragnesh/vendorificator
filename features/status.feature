Feature: Module status

The `status` subcommand displays all known modules and their status.

Background:
  Given a repository with following Vendorfile:
    """ruby
    vendor 'generated', :version => '0.23' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """

Scenario: status new module
  When I successfully run `vendor status`
  Then the last output should match /new\s+generated\/0.23/

Scenario: status up-to-date module
  When I successfully run `vendor sync`
  And I successfully run `vendor status`
  Then the last output should match /up to date\s+generated\/0.23/

Scenario: status outdated modules
  When I successfully run `vendor sync`
  And I change Vendorfile to:
    """ruby
    vendor 'generated', :version => '0.42' do |v|
      File.open('README', 'w') { |f| f.puts "Hello, Updated, World!" }
      File.open('VERSION', 'w') { |f| f.puts v.version }
    end
    """
  And I successfully run `vendor status`
  Then the last output should match /outdated\s+generated\/0.42/

Scenario: Module's dependencies are statused if they are known
  When I change Vendorfile to:
    """ruby
    require 'vendorificator/vendor/chef_cookbook'
    chef_cookbook 'memcached'
    """
  And I successfully run `vendor status`
  Then the last output should match /new\s+memcached/
  And the last output should not match "runit"
  When I successfully run `vendor sync`
  And I successfully run `vendor status`
  Then the last output should match /up to date\s+memcached/
  And the last output should match /up to date\s+runit/
