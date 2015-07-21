##2015-07-08 - 6.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Kilo.

####Backwards-incompatible changes
- Remove deprecated class (swift::proxy::proxy-logging)
- Use keystonemiddleware instead of client
- Removal of SSH Components

####Features
- Puppet 4.x support
- Allow setting reseller_prefix for keystone filter
- Add manage_service feature
- Refactorise Keystone resources management
- Add seed parameter to ringbuilder::rebalance
- Add support for identity_uri
- Provide a mean to change the default rsync chmod
- Add ability to override service name for service catalog
- Add node_timeout parameter for proxy-server.conf
- Full ipv6 support
- Tag all Swift packages
- Notify services if swift.conf is modified
- Add rsyslog logging support to object-server
- Handle both string and array for memcache param
- Introduce public_url(_s3), internal_url(_s3) and admin_url(_s3)
- Add max_header_size field for PKI tokens

####Bugfixes
- Fix swift::proxy::ceilometer

####Maintenance
- Acceptance tests with Beaker

##2015-06-17 - 5.1.0
###Summary

This is a feature and bugfix release in the Juno series.

####Features
- Add seed parameter to ringbuilder::rebalance
- Allow setting reseller_prefix for keystone filter
- Add node_timeout parameter for proxy-server.conf
- Provide a mean to change the default rsync chmod
- Add manage_service feature

####Bugfixes
- Fix concat file mode
- Handle both string and array for memcache param
- read_affinity requires affinity sorting_method
- Remove unused fragment_title variable
- Fix ipv6 support
- Add base `swift` class name to call
- Swift proxy won't start if using proxy:ceilometer
- Correct proxy::authtoken docs
- Notify services if swift.conf is modified
- Use keystonemiddleware instead of client

####Maintenance
- Update .gitreview file for project rename
- mount.pp: fix lint issue
- doc spelling corrections
- Pin puppetlabs-concat to 1.2.1 in fixtures
- Update ssh module version
- Pin fixtures for stables branches
- Remove non-ASCII characters from puppet doc
- Fix spec tests in stable/juno branch

##2014-11-22 - 5.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Juno.

####Backwards-incompatible changes
- Update s3token.conf template for Juno
- Bump stdlib dependency to >=4.0.0

####Features
- Add parameter log_name to swift::proxy and swift::storage::server

##2014-06-20 - 4.1.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add swift-ring-builder multi-region support
- Add swift::proxy::crossdomain class
- Add support for RHEL 7

####Bugfixes
- Fix Swift quota filter names
- Fix config dependency bugs
- Fix resource conflict when ringserver and storage are on same node
- Fix selinux bugs

####Maintenance
- Pin major gems

##2014-05-01 - 4.0.0
###Summary

This is a major release for OpenStack Icehouse but contains no API-breaking
changes.

####Features
- Add support for parameterizing endpoint prefix
- Add read_affinity, write_affinity support to proxy
- Add proxyserver gatekeeper middleware
- Add swift::proxy::slo class
- Add support for allow_versions in Swift containers
- Add support for middlewares with hyphens in name

####Bugfixes
- Fix spurious warning in pipeline check
- Fix test files
- Fix deprecation warnings in inline templates

####Maintenance
- Update swift::keystone::auth spec tests

##2014-02-04 - 3.0.0
###Summary

This is a major release for OpenStack Havana but contains no API-breaking
changes.

####Features
- Added bulk middleware support
- Added quota middleware support
- Allow configuration of admin and internal protocols for keystone endpoint

####Bugfixes
- Fix Puppet 3.x template variable deprecation warning
- Add swift operator roles to Keystone
- Default include_service_catalog to false for improved performance
- Fix auth_token configuration
- Fix filter name for puppetdb

##2013-10-07 - 2.2.0
###Summary

This is a feature and bugfix release in the Grizzly series.

####Features
- Improve proxy directory signing support

####Bugfixes
- Various lint, and deprecation fixes

##2013-08-07 - 2.1.0
###Summary

This is a feature and bugfix release in the Grizzly series.

####Features
- Management of swift-bench
- allow_versions flag for object versioning
- ini_setting based custom types for configs
- Configurable log for proxy-server
- Adds signing directory

####Bugfixes
- Puppet lint and warning fixes

##2013-06-24 - 2.0.0
###Summary

Initial release on StackForge.

####Features
- Upstream is now part of stackforge
- swift_ring_builder supports replicator
- Supports swift 1.8
- Further Red Hat support

####Bugfixes
- Various cleanups and bug fixes
