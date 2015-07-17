##2015-07-08 - 6.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Kilo.

####Backwards-incompatible changes
- Move rabbit/kombu settings to oslo_messaging_rabbit section

####Features
- Puppet 4.x support
- make crontab for expirer optional
- Refactorise Keystone resources management
- db: Added postgresql backend using openstacklib helper
- Implement Ceilometer-API as a WSGI process support
- Add support for ceilometer-polling agent
- Add support for identity_uri
- Tag all Ceilometer packages
- Add udp_address/udp_port parameters for collector.
- Deprecate old public, internal and admin parameters

####Bugfixes
- Ensure python-mysqldb is installed before MySQL db_sync
- Fix dependency on nova-common package

####Maintenance
- Acceptance tests with Beaker
- Fix spec tests for RSpec 3.x and Puppet 4.x


##2015-06-17 - 5.1.0
###Summary

This is a feature and bugfix release in the Juno series.

####Features
- Add support for configuring coordination/backend_url
- Implement Ceilometer-API as a WSGI process support
- Switch to TLSv1

####Bugfixes
- crontab: ensure the script is run with shell
- Change default MySQL collate to utf8_general_ci

####Maintenance
- Pin puppetlabs-concat to 1.2.1 in fixtures
- Update .gitreview file for project rename
- spec: updates for rspec-puppet 2.x and rspec 3.x

##2014-11-20 - 5.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Juno.

####Backwards-incompatible changes
- Migrate the mysql backend to use openstacklib::db::mysql, adding dependency
  on puppet-openstacklib
- Bumped stdlib dependency to >=4.0.0
- Removed deprecation notices for sectionless ceilometer_config types for Juno
  release

####Features
- Added ability to hide secrets from puppet logs
- Add package_ensure parameters to various classes to control package
  installation
- Add ceilometer::policy to control policy.json
- Update validate_re expressions for Puppet 3.7
- Add manage_service parameters to various classes to control whether the
  service was managed, as well as added enabled parameters where not already
  present
- Add parameters to control whether to configure keystone users
- Add the ability to override the keystone service name in
  ceilometer::keystone::auth
  deprecated the mysql_module parameter

####Bugfixes
- Fix ceilometer-notification package name for RHEL

##2014-10-16 - 4.2.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add new class for extended logging options

####Bugfixes
- Fix dependency on nova-common package
- Fix ssl parameter requirements for kombu and rabbit
- Fix mysql_grant call
- Fix ceilometer-collecter service relationships when service is disabled

##2014-06-19 - 4.1.0
###Summary

This is a feature and bigfix release in the Icehouse series.

####Features
- Add RabbitMQ SSL Support

####Bugfixes
- Fix dependency cycle bug
- Fix agent_notification_service_name
- Change default mysql charset to UTF8

####Maintenance
- Pin major gems

##2014-01-05 - 4.0.0
###Summary

This is a major release for OpenStack Icehouse but contains no API-breaking
changes.

####Backwards-incompatible changes

None

####Features
- Add ability to override notification topics
- Implement notification agent service
- Add support for puppetlabs-mysql 2.2 and greater
- Introduce ceilometer::config to handle additional custom options

####Bugfixes
- Fix region name configuration
- Fix ensure packages bug

##2014-03-26 - 3.1.1
###Summary

This is a bugfix release in the Havana series.

####Bugfixes
- Remove enforcement of glance_control_exchange
- Fix user reference in db.pp
- Allow db fields configuration without need for dbsync for better replicaset
  support
- Fix alarm package parameters Debian/Ubuntu

##2014-02-14 - 3.1.0
###Summary

This is a feature and bugfix release in the Havana series.

####Features
- Remove log_dir from params and make logs configurable in init

####Bugfixes
- Fix package ceilometer-alarm type error on Debian
- Remove glance_notifications from notification_topic
- Don't match commented [DEFAULT] section

##2014-01-17 - 3.0.0
###Summary

- Initial release of the puppet-ceilometer module
