# Changes

## 0.3.0

 - New command `vendor push` for pushing managed branches and tags to
   remote repository
 - Nicer syntax for mixin hooks
 - Add `:tag` option for `git` submodule
 - Better stashing of local changes when syncing
 - Verbosity tweaks
 - Refactor implementation of configuration, other internal refactors
 - Improved test coverage

## 0.2.0

 - New vendor type `download` for downloading a single file
 - Support `--version` and `-h` / `--help` switches
 - New `:subdirectory` option for vendor modules
 - Support JRuby
 - Fix error when cleaning empty repository
 - Misc verbosity tweaks
 - Use MiniGit instead of Grit as Git library; other internal refactors
 - Run Cucumber tests with Aruba

## 0.1.1

 - Add `--update` option to `vendor sync` and `vendor status` to check
   whether upstream version has changed
 - It is now possible to explicitly set module's category to `nil`
 - Ruby 1.8.7 compatibility fix
 - Gem runtime/development dependency fixes
 - Initial minitest specs
 - Make Cucumber tests use Webmock

## 0.1.0

Initial release.



