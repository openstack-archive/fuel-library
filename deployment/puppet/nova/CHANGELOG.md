##2015-07-08 - 6.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Kilo.

####Backwards-incompatible changes
- Remove deprecated parameters
- Disable file injection when using RBD as compute ephemeral storage
- Remove Python Package Declaration
- move setting of novncproxy_base_url
- Move rabbit/kombu settings to oslo_messaging_rabbit section
- MySQL: change default MySQL collate to utf8_general_ci
- Moved spice configuration options from DEFAULT to spice section

####Features
- Puppet 4.x support
- Refactorise Keystone resources management
- Configure database parameters on the right nodes
- Add parameters for availability zones configuration
- Migrate postgresql backend to use openstacklib::db::postgresql
- Allow auth_name and auth_name_v3 to be the same
- Add an option to not configure RabbitMQ service
- Database: add slave_connection support
- Support for heal_instance_info_cache_interval
- Only tag packages with openstack tag
- Add PCI Passthrough/SR-IOV support
- Add support for identity_uri
- IPv6 support for migration check
- Allow libvirt secret key setting from param
- Adds OracleLinux support
- Ensure /etc/nova exists before creating secret.xml
- Run db-sync if nova packages are upgraded
- Make package 'bridge-utils' install optional
- Introduce public_url, internal_url and admin_url (and v3/ec2)
- Better handling of package dependencies in nova generic_service
- Add scheduler_driver parameter to nova::scheduler class
- Add parameter to control use of rbd for the ephemeral storage
- Install only required libvirt packages
- keystone/auth: make service description configurable

####Bugfixes
- Fix catalog compilation when not configuring endpoint
- Fix behaviour of 'set-secret-value virsh' exec
- Fix variable access in RBD secret template

####Maintenance
- Acceptance tests with Beaker
- Fix spec tests for RSpec 3.x and Puppet 4.x

##2015-06-17 - 5.1.0
###Summary

This is a feature and bugfix release in the Juno series.

####Features
- Added parameters for availability zones configuration
- IPv6 support for migration check
- Database: add slave_connection support
- supporting lxc cpu mode
- Add serialproxy configuration
- Switch to TLSv1 as SSLv3 is considered insecure and is disabled by default
- Add PCI Passthrough/SR-IOV support
- Add Ironic support into nova puppet modules

####Bugfixes
- Move setting of novncproxy_base_url
- crontab: ensure nova-common is installed before
- Correct docs on format for nova::policy data
- Allow libvirt secret key setting from param
- Fix behaviour of 'set-secret-value virsh' exec
- MySQL: change default MySQL collate to utf8_general_ci
- Make group on /var/log/nova OS specific
- Correct references to ::nova::rabbit_* variables
- Add optional network_api_class parameter to nova::network::neutron class
- Add Nova Aggregate support
- rpc_backend: simplify parameters
- virsh returns a list of secret uuids, not keyring names
- Disable file injection when using RBD as compute ephemeral storage
- Correct section for cell_type nova.conf parameter
- crontab: ensure the script is run with shell
- Configure database parameters on the right nodes

####Maintenance
- Pin puppetlabs-concat to 1.2.1 in fixtures
- Pin fixtures for stables branches
- spec: pin rspec-puppet to 1.0.1

##2014-11-24 - 5.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Juno.

####Backwards-incompatible changes
- Update the [glance] and [neutron] section parameters for Juno
- Bump stdlib dependency to >=4.0.0
- Update nova quota parameters for Juno
- Migrate the ceilometer::db::mysql class to use openstacklib::db::mysql,
  adding new dependency on openstacklib
- Removed deprecation notice for sectionless nova_config names

####Features
- Add tags to all nova packages
- Add parameter dhcp_domain to nova class
- Add parameters for nova service validation to nova::api
- Add nova::policy to control policy.json
- Add force_raw_images parameter to nova::compute class
- Add parameter ec2_workers to nova::api
- Add parameter rabbit_ha_queues to nova class
- Add parameter pool to nova_floating type
- Add parameters to control whether to configure keystone users
- Add nova::cron::archive_deleted_rows class to create a crontab for archiving
  deleted database rows
- Add parameter keystone_ec2_url to nova::api
- Add the ability to override the keystone service name in
  ceilometer::keystone::auth
- Add parameter workers to in nova::conductor and deprecate conductor_workers
  in nova::api
- Add parameter vnc_keymap in nova::compute
- Add parameter osapi_v3 to nova::api

####Bugfixes
- Fix potential duplicate declaration errors for sysctl::value in nova::network
- Fix dependency cycle in nova::migration::libvirt
- Update the libvirtd init script path for Debian
- Fix the rabbit_virtual_host default in nova::cells
- Fix bug in usage of --vlan versus --vlan_start in nova_network provider
- Change the keystone_service to only be configured if the endpoint is to be
  configured
- Remove dynamic scoping of File resources in nova class

####Maintenance
- Replace usage of the keyword type with the string 'type' since type is a
  reserved keyword in puppet 3.7

##2014-11-17 - 4.2.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add option to configure libvirt service name via class parameters
- Add support for multiple SSL APIs
- Add option to configure os_region_name in the nova config
- Add class for extended logging options

####Bugfixes
- Correct resource dependencies on the nova user
- Fix os version fact comparison for RedHat-based operating systems
  for specifying service provider
- Fix ssl parameter requirements when using kombu and rabbit

##2014-06-20 - 4.1.0
###Summary

This is a feature and bugfix release in the Icehouse series.

####Features
- Add API v3 endpoint support
- Add configuration of rbd keyring name
- Add support for run Nova SSL endpoints

####Bugfixes
- Update RabbitMQ dependency
- Update mysql charset to UTF8

####Maintenance
- Pin major gems

##2014-05-01 - 4.0.0
###Summary

This is a major release for OpenStack Icehouse but contains no API-breaking
changes.

####Features
- Add support for RHEL 7
- Add support for metadata and conductor workers
- Add support for vif_plugging parameters
- Add support for puppetlabs-mysql 2.2 and greater
- Add support for instance_usage_audit parameters
- Add support to manage the nova uid/gid for NFS live migration
- Add nova::config to handle additional custom options
- Add support to disable installation of nova utilities
- Add support for durable RabbitMQ queues
- Add SSL support for RabbitMQ
- Add support for nova-objectstore bind address

####Bugfixes
- Update support for notification parameters
- Fix packaging bugs
- Fix report_interval configuration
- Fix file location for nova compute rbd secret

##2014-04-15 - 3.2.1
###Summary

This is a bugfix release in the Havana series.

####Bugfixes
- Fix consoleauth/spice resource duplication on Red Hat systems

##2014-03-26 - 3.2.0
###Summary

This is a feature and bugfix release in the Havana series.

####Features
- Deprecate logdir parameter in favor of log_dir
- Allow log_dir to be set to false in order to disable file logging
- Add RBD backend support for VM image storage
- Parameterize libvirt cpu_mode and disk_cachemodes
- Add support for https auth endpoints
- Add ability to disable installation of nova utilities

####Bugfixes
- Replace pip with native package manager for VMWare
- Enable libvirt at boot

##2014-02-14 - 3.1.0
###Summary

This is a bugfix release in the Havana series.

####Bugfixes
- Add libguestfs-tools package to nova utilities
- Fix vncproxy package naming for Ubuntu
- Fix libvirt configuration

##2014-01-13 - 3.0.0
###Summary

This is a backwards-incompatible major release for OpenStack Havana.

####Backwards-incompatible changes

- Remove api-paste.ini configuration

####Features
- Add support for live migrations with using the libvirt Nova driver
- Add support for VMWareVCDriver

####Bugfixes
- Fix bug to ensure keystone endpoint is set before service is started
- Fix nova-spiceproxy support on Ubuntu

##2013-10-07 - 2.2.0
###Summary

This is a feature and bugfix release in the Grizzly series.

####Features
- Add a check to install bridge-utils only if needed
- Add syslog support
- Add installation of pm-utils for VM power management support

####Bugfixes
- Fix cinder include dependency bug

##2013-08-07 - 2.1.0
###Summary

This is a feature and bugfix release in the Grizzly series.

####Features
- Add support for X-Forwarded-For HTTP Headers
- Add html5 spice support
- Add config drive support
- Add RabbitMQ clustering support
- Add memcached support
- Add SQL idle timeout support

####Bugfixes
- Fix allowed_hosts/database connection bug

####Maintenance
- Pin RabbitMQ and database module versions

##2013-06-24 - 2.0.0
###Summary

Initial release on StackForge.

####Features
- The ini_file type is now used by nova_config
- Support for nova-conductor added
- Networks can now be labeled by Class['nova::manage::network']
- The Apache Qpid message broker is available as an RPC backend
- Further compatibility fixes for RHEL and its derivatives
- Postgres support added
- Adjustments to help in supporting the still in development neutron module
- Config changes can be hidden from Puppet logs
- Move from deprecated rabbit_notifier to rpc_notifier
