nova
====

4.0.0 - 2014.1.0 - Icehouse

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

To utilize the nova module's functionality you will need to declare multiple resources.  The following is a modified excerpt from the [openstack module](https://github.com/stackfoge/puppet-openstack).  This is not an exhaustive list of all the components needed, we recommend you consult and understand the [openstack module](https://github.com/stackfoge/puppet-openstack) and the [core openstack](http://docs.openstack.org) documentation.

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
* The Nova Openstack service depends on a sqlalchemy database. If you are using puppetlabs-mysql to achieve this, there is a parameter called mysql_module that can be used to swap between the two supported versions: 0.9 and 2.2. This is needed because the puppetlabs-mysql module was rewritten and the custom type names have changed between versions.

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation

Contributors
------------

* https://github.com/stackforge/puppet-nova/graphs/contributors

Release Notes
-------------

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

* Upstream is now part of stackfoge.
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
