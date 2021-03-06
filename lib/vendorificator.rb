# Require everything except the CLI.

require "vendorificator/version"

require 'vendorificator/config'
require 'vendorificator/environment'
require 'vendorificator/errors'

require 'vendorificator/vendor'
require 'vendorificator/vendor/download'
require 'vendorificator/vendor/archive'
require 'vendorificator/vendor/git'
require 'vendorificator/vendor/chef_cookbook'
