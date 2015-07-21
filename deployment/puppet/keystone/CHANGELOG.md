##2015-07-08 - 6.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Kilo.

####Backwards-incompatible changes
- Remove deprecated parameters
- MySQL: change default MySQL collate to utf8_general_ci
- Move openstackclient to openstacklib

####Features
- Puppet 4.x support
- Support Keystone v3 API
- Allow disabling or delaying the token_flush cron
- Migrate postgresql backend to use openstacklib::db::postgresql
- Add max_token_size optional parameter
- Add admin_workers and public_workers configuration options
- Add support for LDAP connection pools
- Add a package ensure for openstackclient
- Enable setting the revoke/token driver
- Add manage_service feature
- Makes distinct use of url vs auth_url
- Create a sync_db boolean for Keystone
- LDAP: add support to configure credential driver
- Support notification_format
- Allow custom file source for wsgi scripts
- Decouple sync_db from enabled
- Add support for Fernet Tokens

####Bugfixes
- Crontab: ensure the script is run with bash shell
- Copy latest keystone.py from Keystone upstream
- Fix deprecated LDAP config options
- Fix service keystone conflict when running in apache

####Maintenance
- Acceptance tests with Beaker
- Fix spec tests for RSpec 3.x and Puppet 4.x
- Restructures authentication for resource providers

##2015-06-17 - 5.1.0
###Summary

This is a features and bugfixes release in the Juno series.

####Features
- Allow disabling or delaying the token_flush cron
- Use openstackclient for keystone_* providers
- Switch to TLSv1
- Handle missing project/tenant when using ldap backend
- Add support for LDAP connection pools
- Support the ldap user_enabled_invert parameter
- Tag packages with 'openstack'
- Add ::keystone::policy class for policy management
- New option replace_password for keystone_user
- Set WSGI process display-name
- Add native types for keystone paste configuration

####Bugfixes
- crontab: ensure the script is run with shell
- service_identity: add user/role ordering
- Fix password check for SSL endpoints
- Add require json for to_json dependency
- Sync keystone.py with upstream to function with Juno
- Allow Keystone to be queried when using IPv6 ::0

####Maintenance
* spec: pin rspec-puppet to 1.0.1
* Pin puppetlabs-concat to 1.2.1 in fixtures
* Update .gitreview file for project rename

##2014-11-24 - 5.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Juno.

####Backwards-incompatible changes
- Update token driver, logging, and ldap config parameters for Juno
- Make UUID the default token provider
- Migrate the keystone::db::mysql class to use openstacklib::db::mysql, adding
  dependency on openstacklib

####Features
- Change admin_roles parameter to accept an array in order to configure
  multiple admin roles
- Add new parameters to keystone class to configure pki signing
- Add parameters to control whether to configure users
- Deprecate the mysql_module parameter
- Enable setting cert and key paths for PKI token signing
- Add parameters for SSL communication between keystone and rabbitmq
- Add parameter ignore_default_tenant to keystone::role::admin
- Add parameter service_provider to keystone class
- Add parameters for service validation to keystone class

####Bugfixes
- Install python-ldappool package for ldap
- Change keystone class to inherit from keystone::params
- Change pki_setup to run regardless of token provider
- Stop managing _member_ role since it is created automatically
- Stop overriding token_flush log file
- Change the usage of admin_endpoint to not include the API version
- Allow keystone_user_role to accept email as username
- Add ability to set up keystone using Apache mod_wsgi
- Make keystone_user_role idempotent
- Install python-memcache when using token driver memcache

##2014-10-16 - 4.2.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add class for extended logging options
- Add parameters to set tenant descriptions

####Bugfixes
- Fix rabbit password leaking
- Fix keystone user authorization error handling

##2014-06-19 - 4.1.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add token flushing with cron

####Bugfixes
- Update database api for consistency with other projects
- Fix admin_token with secret parameter
- Fix deprecated catalog driver

##2014-05-05 - 4.0.0
###Summary

This is a major release for OpenStack Icehouse but contains no API-breaking
changes.

####Features
* Add template_file parameter to specify catalog
* Add keystone::config to handle additional custom options
* Add notification parameters
* Add support for puppetlabs-mysql 2.2 and greater

####Bugfixes
- Fix deprecated sql section header in keystone.conf
- Fix deprecated bind_host parameter
- Fix example for native type keystone_service
- Fix LDAP module bugs
- Fix variable for host_access dependency
- Reduce default token duration to one hour

##2014-04-15 - 3.2.0
###Summary

This is a feature and bugfix release in the Havana series.

####Features
- Add ability to configure any catalog driver

####Bugfixes
- Ensure log_file is absent when using syslog

##2014-03-28 - 3.1.1
###Summary

This is a bugfix release in the Havana series.

####Bugfixes
- Fix inconsistent variable for mysql allowed hosts

##2014-03-26 - 3.1.0
###Summary

This is a feature and bugfix release in the Havana series.

####Features
- Add ability to disable pki_setup
- Add log_dir param, with option to disable
- Add support to enable SSL

####Bugfixes
- Load tenant un-lazily if needed
- Update endpoint argument
- Remove setting of Keystone endpoint by default
- Relax regex when keystone refuses connections

##2014-01-16 - 3.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Havana.

####Backwards-incompatible changes
- Move db_sync to its own class
- Remove creation of Member role
- Switch from signing/format to token/provider

####Features
- Create memcache_servers option to allow for multiple cache servers
- Enable serving Keystone from Apache mod_wsgi
- Improve performance of Keystone providers
- Update endpoints to support paths and ssl
- Add support for token expiration parameter

####Bugfixes
- Fix duplicated keystone endpoints
- Refactor keystone_endpoint to use prefetch and flush paradigm

##2013-10-07 - 2.2.0
###Summary

This is a feature and bugfix release in the Grizzly series.

####Features
- Optimized tenant and user queries
- Added syslog support
- Added support for token driver backend

####Bugfixes
- Various bug and lint fixes

##2013-08-06 - 2.1.0
###Summary

This is a bugfix release in the Grizzly series.

####Bugfixes
- Fix allowed_hosts contitional statement
- Select keystone endpoint based on SSL setting
- Improve tenant_hash usage in keystone_tenant
- Various cleanup and bug fixes

####Maintenance
- Pin dependencies

##2013-06-18 - 2.0.0
###Summary

Initial release on StackForge.

####Backwards-incompatible changes

####Features
- keystone_user can be used to change passwords
- service tenant name now configurable
- keystone_user is now idempotent

####Bugfixes
- Various cleanups and bug fixes
