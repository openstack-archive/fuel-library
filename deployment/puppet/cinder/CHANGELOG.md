##2015-07-08 - 6.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Kilo.

####Backwards-incompatible changes
- Iscsi: Change default $volume_driver
- Switch to TLSv1 as SSLv3 is considered insecure and is disabled by default
- Remove POSIX users, groups, and file modes
- Move rabbit/kombu settings to oslo_messaging_rabbit section
- Also removed deprecated parameters

####Features
- Puppet 4.x support
- Refactorise Keystone resources management
- Add an option to not configure RabbitMQ service
- Run db_sync when upgrading packages
- Makes kombu_ssl_* parameters optional when rabbit_use_ssl => true
- Adds ability to override service name for service catalog
- Support the enable_v*_api settings
- Support iSER driver within the ISCSITarget flow
- ISCSI: Allow one to specify volumes_dir path
- Backends: Add an extra_options door
- Support identity_uri and auth_uri properly
- Make scheduler_driver option can be cleaned up
- Tag all Cinder packages
- Adds OracleLinux support
- Create a sync_db boolean for Cinder
- Update NetApp params for Kilo
- Add nfs_mount_options variable when backend is NetApp
- Add support for NFS Backup
- Decouple $sync_db from $enabled
- Add backup compression parameter
- Introduce public_url, internal_url and admin_url
- Added support for DellStorageCenter ISCSI cinder driver
- Add cinder::scheduler::filter for managing scheduler.filter
- NetApp: use $name for configuration group name (allows to run multiple NetApp
  backends)
- Lint documentation parameters
- HP 3par iscsi backend module
- MySQL: change default MySQL collate to utf8_general_ci

####Bugfixes
- Fix db_sync dependencies

####Maintenance
- Acceptance tests with Beaker
- Fix spec tests for RSpec 3.x and Puppet 4.x

##2015-06-17 - 5.1.0
###Summary

This is a feature and bugfix release in the Juno series.

####Features
- Service Validation for Cinder-API
- Automate generation of NFS config file
- Make kombu_ssl_* parameters optional when rabbit_use_ssl => true
- Switch to TLSv1
- Add nfs_mount_options variable when backend is NetApp
- Add configuration helpers for Quobyte
- Implement HP 3par iscsi backend module

####Bugfixes
- Switch to using the new SolidFire driver name
- Create type-key only if it doesn't exist
- use lioadm on Fedora
- Change default MySQL collate to utf8_general_ci

####Maintenance
- spec: pin rspec-puppet to 1.0.1
- Pin puppetlabs-concat to 1.2.1 in fixtures
- Update .gitreview file for project rename

##2014-11-20 - 5.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Juno.

####Backwards-incompatible changes
- Change the default value of the san_thin_provision parameter for eqlx
- Migrate the mysql backend to use openstacklib::db::mysql, adding dependency
  on puppet-openstacklib

####Features
- Add class to manage policy.json
- Add database tuning parameters
- Made keystone user creation optional when creating a service
- Add ability to hide secrets from logs
- Add parameters for netapp and and cinder-api workers
- Add support for the EMC VNX direct driver
- Add support for availability zones

####Bugfixes
- Correct the package name for cinder backup

##2014-10-16 - 4.2.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add parameters to set cinder volume driver
- Add class for extended logging options
- Add option to specify endpoint protocol
- Add option to specify cinder volume path
- Add option to configure os_region_name in the cinder config

####Bugfixes
- Fix cinder type path issues
- Fix targetcli package dependency on target service
- Fix os version fact comparison for RedHat-based operating systems for
  specifying service provider

##2014-06-19 - 4.1.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add Cinder v2 endpoint support
- Add SSL support for Cinder API
- Add RabbitMQ SSL support

####Bugfixes
- Move default_volume_type to cinder::api
- Remove warnings for existing Cinder volumes

####Maintenance
- Pin major gems

##2014-01-29 - 4.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Icehouse.

####Backwards-incompatible changes
- Remove control exchange flag
- Remove deprecated cinder::base class
- Update NetApp unified driver config options

####Features
- Update support for latest RabbitMQ module
- Add Glance support
- Add GlusterFS driver support
- Add region support
- Add support for MySQL module (>= 2.2)
- Add support for Swift and Ceph backup backend
- Add cinder::config to handle additional custom options
- Refactor duplicate code for single and multiple backends

####Bugfixes

None

##2014-04-15 - 3.1.1
###Summary

This is a bugfix release in the Havana series.

####Bugfixes
- Fix resource duplication bug

##2014-03-26 - 3.1.0
###Summary

This is a feature and bugfix release in the Havana series.

####Features
- Add default_volume_type as a Cinder API parameter
- Add parameter for endpoint protocols
- Deprecate glance_api_version
- Add support for VMDK
- Add support for Cinder multi backend
- Add support for https authentication endpoints

####Bugfixes
- Replace pip with native package manager (VMDK)

##2014-01-13 - 3.0.0
###Summary

This is a major release for OpenStack Havana but contains no API-breaking
changes.

####Features
- Add support for SolidFire
- Add support for ceilometer

####Bugfixes
- Fix bug for cinder-volume requirement

##2013-10-07 - 2.2.0
###Summary

This is a feature and bugfix release in the Grizzly series.

####Features
- Add support for rate limiting via api-paste.ini
- Add support to configure control_exchange
- Add parameter check to enable or disable db_sync
- Add syslog support
- Add default auth_uri setting for auth token
- Set package defaults to present

####Bugfixes
- Fix a bug to create empty init script when necessary

####Maintenance
- Various lint fixes

##2013-08-07 - 2.1.0
###Summary

This is a feature and bugfix release in the Grizzly series.

####Features
- Add configuration of Cinder quotas
- Add support for NetApp direct driver backend
- Add support for ceph backend
- Add support for SQL idle timeout
- Add support for RabbitMQ clustering with single IP

####Bugfixes
- Fix allowed_hosts/database connection bug
- Fix lvm2 setup failure for Ubuntu
- Remove unnecessary mysql::server dependency

####Maintenance
- Pinned RabbitMQ and database module versions
- Various lint and bug fixes

##2013-06-24 - 2.0.0
###Summary

Initial release on Stackforge.

####Features
- Nexenta, NFS, and SAN support added as cinder volume drivers
- Postgres support added
- The Apache Qpid and the RabbitMQ message brokers available as RPC backends
- Configurability of scheduler_driver
