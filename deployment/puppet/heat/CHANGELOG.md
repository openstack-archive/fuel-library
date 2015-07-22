##2015-07-08 - 6.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Kilo.

####Backwards-incompatible changes
- Move rabbit/kombu settings to oslo_messaging_rabbit section

####Features
- Puppet 4.x support
- Implement Keystone domain creation
- Log output of heat-keystone-setup-domain
- Refactorise Keystone resources management
- Move keystone role creation to keystone area
- Support region_name for Heat
- Mark heat's keystone password as secret
- Add support for identity_uri
- Make configuring the service optional
- Set instance_user in heat
- Added missing enable_stack_abandon configuration option
- Tag all Heat packages
- Create a sync_db boolean for Heat
- Engine: validate auth_encryption_key
- Allow setting default config/signal transport
- Run db_sync when heat-common is upgraded
- Introduce public_url, internal_url and admin_url

####Maintenance
- Acceptance tests with Beaker
- Fix spec tests for RSpec 3.x and Puppet 4.x
- Rename keystone_v2_authenticate method
- Make package_ensure consistent across classes

##2015-06-17 - 5.1.0
###Summary

This is a feature and bugfix release in the Juno series.

####Features
- Switch to TLSv1
- Implement Keystone domain creation
- Run dbsync when engine is upgraded
- db: Added postgresql backend using openstacklib helper
- Add option to configure flavor in heat.conf

####Bugfixes
- Rework delegated roles
- Change default MySQL collate to utf8_general_ci
- Fix ipv6 support

####Maintenance
- spec: pin rspec-puppet to 1.0.1
- Pin puppetlabs-concat to 1.2.1 in fixtures
- Update .gitreview file for project rename

##2014-11-24 - 5.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Juno.

####Backwards-incompatible changes
- Bump stdlib dependency to >=4.0.0

####Features
- Add heat::policy to control policy.json
- Deprecate the sql_connection parameter for database_connection parameter
- Add parameters to configure deferred authentication method in heat::engine in
  accordance with new Juno defaults
- Add parameters to control whether to configure users
- Add manage_service parameters to various classes to control whether the
  service was managed, as well as added enabled parameters where not already
  present
- Add the ability to override the keystone service name in keystone::auth
- Migrate the heat::db::mysql class to use openstacklib::db::mysql and
  deprecated the mysql_module parameter

##2014-10-16 - 4.2.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Backwards-incompatible changes

####Features
- Add ability to hide secret type parameters from logs
- Add class for extended logging options

####Bugfixes
- Fix database resource relationships
- Fix ssl parameter requirements when using kombu and rabbit

##2014-06-19 - 4.1.0
###Summary

This is a feature release in the Icehouse series.

####Features
- Added SSL endpoint support

##2014-05-05 - 4.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Icehouse.

####Backwards-incompatible changes
- Fix outdated DB connection parameter

####Features
- Add SSL parameter for RabbitMQ
- Add support for puppetlabs-mysql 2.2 and greater
- Add option to define RabbitMQ queues as durable

####Bugfixes
- Fix Keystone auth_uri parameter

##2014-03-26 - 3.1.0
###Summary

This is a feature and bugfix release in the Havana series.

####Features
- Allow log_dir to be set to false to disable file logging
- Add support for database idle timeout

####Bugfixes
- Fix postgresql connection string
- Align Keystone auth_uri with other OpenStack services
- Fix the EC2 auth token settings
- Fix rabbit_virtual_host configuration

##2014-01-23 - 3.0.0
###Summary

Initial release of the puppet-heat module.
