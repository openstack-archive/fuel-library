nova
====

5.1.0 - 2014.2 - Juno

#### Table of Contents

1. [Overview - What is the nova module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with nova](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The nova module is a part of [Stackforge](https://github.com/stackforge), an effort by the Openstack infrastructure team to provide continuous integration testing and code review for Openstack and Openstack community projects not part of the core software.  The module its self is used to flexibly configure and manage the compute service for Openstack.

Module Description
------------------

The nova module is a thorough attempt to make Puppet capable of managing the entirety of nova.  This includes manifests to provision such things as keystone endpoints, RPC configurations specific to nova, and database connections.  Types are shipped as part of the nova module to assist in manipulation of configuration files.

This module is tested in combination with other modules needed to build and leverage an entire Openstack software stack.  These modules can be found, all pulled together in the [openstack module](https://github.com/stackforge/puppet-openstack).

Setup
-----

**What the nova module affects:**

* nova, the compute service for Openstack.

### Installing nova

    example% puppet module install puppetlabs/nova

### Beginning with nova

To utilize the nova module's functionality you will need to declare multiple resources.  The following is a modified excerpt from the [openstack module](https://github.com/stackforge/puppet-openstack).  This is not an exhaustive list of all the components needed, we recommend you consult and understand the [openstack module](https://github.com/stackforge/puppet-openstack) and the [core openstack](http://docs.openstack.org) documentation.

```puppet
class { 'nova':
  database_connection => 'mysql://nova:a_big_secret@127.0.0.1/nova?charset=utf8',
  rabbit_userid       => 'nova',
  rabbit_password     => 'an_even_bigger_secret',
  image_service       => 'nova.image.glance.GlanceImageService',
  glance_api_servers  => 'localhost:9292',
  verbose             => false,
  rabbit_host         => '127.0.0.1',
}

class { 'nova::compute':
  enabled                       => true,
  vnc_enabled                   => true,
}

class { 'nova::compute::libvirt':
  migration_support => true,
}
```

Implementation
--------------

### nova

nova is a combination of Puppet manifest and ruby code to delivery configuration and extra functionality through types and providers.

Limitations
-----------

* Supports libvirt, xenserver and vmware compute drivers.
* Tested on EL and Debian derivatives.

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation


Beaker-Rspec
------------

This module has beaker-rspec tests

To run the tests on the default vagrant node:

```shell
bundle install
bundle exec rspec spec/acceptance
```

For more information on writing and running beaker-rspec tests visit the documentation:

* https://github.com/puppetlabs/beaker/wiki/How-to-Write-a-Beaker-Test-for-a-Module

Contributors
------------

* https://github.com/stackforge/puppet-nova/graphs/contributors

Release Notes
-------------

**5.1.0**

* move setting of novncproxy_base_url
* Added parameters for availability zones configuration
* crontab: ensure nova-common is installed before
* Correct docs on format for nova::policy data
* Allow libvirt secret key setting from param
* Fix behaviour of 'set-secret-value virsh' exec
* MySQL: change default MySQL collate to utf8_general_ci
* Pin puppetlabs-concat to 1.2.1 in fixtures
* Make group on /var/log/nova OS specific
* IPv6 support for migration check.
* Database: add slave_connection support
* Correct references to ::nova::rabbit_* variables
* Add optional network_api_class parameter to nova::network::neutron class
* Add Nova Aggregate support
* rpc_backend: simplify parameters
* supporting lxc cpu mode Fixing the default cpu_mode from None to none
* virsh returns a list of secret uuids, not keyring names
* Pin fixtures for stables branches
* Add serialproxy configuration
* Switch to TLSv1 as SSLv3 is considered insecure and is disabled by default
* Disable file injection when using RBD as compute ephemeral storage
* Add PCI Passthrough/SR-IOV support
* Add Ironic support into nova puppet modules
* spec: pin rspec-puppet to 1.0.1
* Correct section for cell_type nova.conf parameter
* crontab: ensure the script is run with shell
* Configure database parameters on the right nodes

**5.0.0**

* Stable Juno release
* Added tags to all nova packages
* Added parameter dhcp_domain to nova class
* Updated the [glance] and [neutron] section parameters for Juno
* Fixed potential duplicate declaration errors for sysctl::value in nova::network
* Fixed dependency cycle in nova::migration::libvirt
* Updated the libvirtd init script path for Debian
* Added parameters for nova service validation to nova::api
* Added nova::policy to control policy.json
* Fixed the rabbit_virtual_host default in nova::cells
* Bumped stdlib dependency to >=4.0.0
* Added force_raw_images parameter to nova::compute class
* Replaced usage of the keyword type with the string 'type' since type is a reserved keyword in puppet 3.7
* Added parameter ec2_workers to nova::api
* Fixed bug in usage of --vlan versus --vlan_start in nova_network provider
* Added parameter rabbit_ha_queues to nova class
* Added parameter pool to nova_floating type
* Added parameters to control whether to configure keystone users
* Added nova::cron::archive_deleted_rows class to create a crontab for archiving deleted database rows
* Changed the keystone_service to only be configured if the endpoint is to be configured
* Added parameter keystone_ec2_url to nova::api
* Added the ability to override the keystone service name in ceilometer::keystone::auth
* Removed dynamic scoping of File resources in nova class
* Add parameter workers to in nova::conductor and deprecate conductor_workers in nova::api
* Update nova quota parameters for Juno
* Migrated the ceilometer::db::mysql class to use openstacklib::db::mysql and deprecated the mysql_module parameter
* Removed deprecation notice for sectionless nova_config names
* Added parameter vnc_keymap in nova::compute
* Added parameter osapi_v3 to nova::api

**4.2.0**

* Added option to configure libvirt service name via class parameters
* Added support for multiple SSL APIs
* Added option to configure os_region_name in the nova config
* Corrected resource dependencies on the nova user
* Fixed os version fact comparison for RedHat-based operating systems
  for specifying service provider
* Fixed ssl parameter requirements when using kombu and rabbit
* Added class for extended logging options

**4.1.0**

* Added API v3 endpoint support.
* Added configuration of rbd keyring name.
* Added support for run Nova SSL endpoints.
* Updated RabbitMQ dependency.
* Updated mysql charset to UTF8.
* Pinned major gems.

**4.0.0**

* Stable Icehouse release.
* Added support for RHEL 7.
* Added support for metadata and conductor workers.
* Added support for vif_plugging parameters.
* Added support for puppetlabs-mysql 2.2 and greater.
* Added support for instance_usage_audit parameters.
* Added support to manage the nova uid/gid for NFS live migration..
* Added nova::config to handle additional custom options.
* Added support to disable installation of nova utilities.
* Added support for durable RabbitMQ queues.
* Added SSL support for RabbitMQ.
* Added support for nova-objectstore bind address.
* Updated support for notification parameters.
* Fixed packaging bugs.
* Fixed report_interval configuration.
* Fixed file location for nova compute rbd secret.

**3.2.1**

* Fixed consoleauth/spice resource duplication on Red Hat systems.

**3.2.0**

* Replace pip with native package manager for VMWare.
* Deprecated logdir parameter in favor of log_dir.
* Allows log_dir to be set to false in order to disable file logging.
* Enables libvirt at boot.
* Adds RBD backend support for VM image storage.
* Parameterizes libvirt cpu_mode and disk_cachemodes.
* Adds support for https auth endpoints.
* Adds ability to disable installation of nova utilities.

**3.1.0**

* Minor release for OpenStack Havana.
* Add libguestfs-tools package to nova utilities.
* Fixed vncproxy package naming for Ubuntu.
* Fixed libvirt configuration.

**3.0.0**

* Major release for OpenStack Havana.
* Removed api-paste.ini configuration.
* Adds support for live migrations with using the libvirt Nova driver.
* Fixed bug to ensure keystone endpoint is set before service is started.
* Fixed nova-spiceproxy support on Ubuntu.
* Added support for VMWareVCDriver.

**2.2.0**

* Added a check to install bridge-utils only if needed.
* Added syslog support.
* Added installation of pm-utils for VM power management support.
* Fixed cinder include dependency bug.
* Various bug and lint fixes.

**2.1.0**

* Added support for X-Forwarded-For HTTP Headers.
* Added html5 spice support.
* Added config drive support.
* Added RabbitMQ clustering support.
* Added memcached support.
* Added SQL idle timeout support.
* Fixed allowed_hosts/database connection bug.
* Pinned RabbitMQ and database module versions.

**2.0.0**

* Upstream is now part of stackforge.
* The ini_file type is now used by nova_config.
* Support for nova-conductor added.
* Networks can now be labeled by Class['nova::manage::network'].
* The Apache Qpid message broker is available as an RPC backend.
* Further compatibility fixes for RHEL and its derivatives.
* Postgres support added.
* Adjustments to help in supporting the still in development neutron module.
* Config changes can be hidden from Puppet logs.
* Move from deprecated rabbit_notifier to rpc_notifier.
* Various cleanups and bug fixes.
