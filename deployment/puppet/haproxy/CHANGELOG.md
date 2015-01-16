##2015-03-10 - Supported Release 1.2.0
###Summary
This release adds flexibility for configuration of balancermembers and bind settings, and adds support for configuring peers. This release also renames the `tests` directory to `examples`

####Features
- Add support for loadbalancer members without ports
- Add `haproxy_version` fact (MODULES-1619)
- Add `haproxy::peer` and `haproxy::peers` defines
- Make `bind` parameter processing more flexible

####Bugfixes
- Fix 'RedHat' name for osfamily case in `haproxy::params`
- Fix lint warnings
- Don't set a default for `ipaddress` so bind can be used (MODULES-1497)

##2014-11-04 - Supported Release 1.1.0
###Summary

This release primarily adds greater flexibility in the listen directive.

####Features
- Added `bind` parameter to `haproxy::frontend`

####Deprecations
- `bind_options` in `haproxy::frontend` is being deprecated in favor of `bind`
- Remove references to deprecated concat::setup class and update concat dependency

##2014-07-21 - Supported Release 1.0.0
###Summary

This supported release is the first stable release of haproxy! The updates to
this release allow you to customize pretty much everything that HAProxy has to
offer (that we could find at least).

####Features
- Brand new readme
- Add haproxy::userlist defined resource for managing users
- Add haproxy::frontend::bind_options parameter
- Add haproxy::custom_fragment parameter for arbitrary configuration
- Add compatibility with more recent operating system releases

####Bugfixes
- Check for listen/backend with the same names to avoid misordering
- Removed warnings when storeconfigs is not being used
- Passing lint
- Fix chroot ownership for global user/group
- Fix ability to uninstall haproxy
- Fix some linting issues
- Add beaker-rspec tests
- Increase unit test coverage
- Fix balancermember server lines with multiple ports

##2014-05-28 - Version 0.5.0
###Summary

The primary feature of this release is a reorganization of the
module to match best practices.  There are several new parameters
and some bug fixes.

####Features
- Reorganized the module to follow install/config/service pattern
- Added bind_options parameter to haproxy::listen
- Updated tests

####Fixes
- Add license file
- Whitespace cleanup
- Use correct port in README
- Fix order of concat fragments

##2013-10-08 - Version 0.4.1

###Summary

Fix the dependency for concat.

####Fixes
- Changed the dependency to be the puppetlabs/concat version.

##2013-10-03 - Version 0.4.0

###Summary

The largest feature in this release is the new haproxy::frontend
and haproxy::backend defines.  The other changes are mostly to
increase flexibility.

####Features
- Added parameters to haproxy:
 - `package_name`: Allows alternate package name.
- Add haproxy::frontend and haproxy::backend defines.
- Add an ensure parameter to balancermember so they can be removed.
- Made chroot optional

####Fixes
- Remove deprecation warnings from templates.

##2013-05-25 - Version 0.3.0
####Features
- Add travis testing
- Add `haproxy::balancermember` `define_cookies` parameter
- Add array support to `haproxy::listen` `ipaddress` parameter

####Bugfixes
- Documentation
- Listen -> Balancermember dependency
- Config line ordering
- Whitespace
- Add template lines for `haproxy::listen` `mode` parameter

##2012-10-12 - Version 0.2.0
- Initial public release
- Backwards incompatible changes all around
- No longer needs ordering passed for more than one listener
- Accepts multiple listen ips/ports/server_names
