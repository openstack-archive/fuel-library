glance
=======

4.0.0 - 2014.1.0 - Icehouse

#### Table of Contents

1. [Overview - What is the glance module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with glance](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The glance module is a part of [Stackforge](https://github.com/stackfoge), an effort by the Openstack infrastructure team to provide continuous integration testing and code review for Openstack and Openstack community projects not part of the core software.  The module its self is used to flexibly configure and manage the image service for Openstack.

Module Description
------------------

The glance module is a thorough attempt to make Puppet capable of managing the entirety of glance.  This includes manifests to provision such things as keystone endpoints, RPC configurations specific to glance, and database connections.  Types are shipped as part of the glance module to assist in manipulation of configuration files.

This module is tested in combination with other modules needed to build and leverage an entire Openstack software stack.  These modules can be found, all pulled together in the [openstack module](https://github.com/stackfoge/puppet-openstack).

Setup
-----

**What the glance module affects**

* glance, the image service for Openstack.

### Installing glance

    example% puppet module install puppetlabs/glance

### Beginning with glance

To utilize the glance module's functionality you will need to declare multiple resources.  The following is a modified excerpt from the [openstack module](https://github.com/stackfoge/puppet-openstack).  This is not an exhaustive list of all the components needed, we recommend you consult and understand the [openstack module](https://github.com/stackforge/puppet-openstack) and the [core openstack](http://docs.openstack.org) documentation.

**Define a glance node**

```puppet
class { 'glance::api':
  verbose           => true,
  keystone_tenant   => 'services',
  keystone_user     => 'glance',
  keystone_password => '12345',
  sql_connection    => 'mysql://glance:12345@127.0.0.1/glance',
}

class { 'glance::registry':
  verbose           => true,
  keystone_tenant   => 'services',
  keystone_user     => 'glance',
  keystone_password => '12345',
  sql_connection    => 'mysql://glance:12345@127.0.0.1/glance',
}

class { 'glance::backend::file': }
```

**Setup postgres node glance**

```puppet
class { 'glance::db::postgresql':
  password => '12345',
}
```

**Setup mysql node for glance**

```puppet
class { 'glance::db::mysql':
  password      => '12345',
  allowed_hosts => '%',
}
```

**Setup up keystone endpoints for glance on keystone node**

```puppet
class { 'glance::keystone::auth':
  password         => '12345'
  email            => 'glance@example.com',
  public_address   => '172.17.0.3',
  admin_address    => '172.17.0.3',
  internal_address => '172.17.1.3',
  region           => 'example-west-1',
}
```

**Setup up notifications for multiple RabbitMQ nodes**

```puppet
class { 'glance::notify::rabbitmq':
  rabbit_password               => 'pass',
  rabbit_userid                 => 'guest',
  rabbit_hosts                  => [
    'localhost:5672', 'remotehost:5672'
  ],
  rabbit_use_ssl                => false,
}
```

Implementation
--------------

### glance

glance is a combination of Puppet manifest and ruby code to deliver configuration and extra functionality through types and providers.

Limitations
------------

* Only supports configuring the file, swift and rbd storage backends.

* The Glance Openstack service depends on a sqlalchemy database. If you are using puppetlabs-mysql to achieve this, there is a parameter called mysql_module that can be used to swap between the two supported versions: 0.9 and 2.2. This is needed because the puppetlabs-mysql module was rewritten and the custom type names have changed between versions.

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation

Contributors
------------

* https://github.com/stackforge/puppet-glance/graphs/contributors

Release Notes
-------------

**4.0.0**

* Stable Icehouse release.
* Added glance::config to handle additional custom options.
* Added known_stores option for glance::api.
* Added copy-on-write cloning of images to volumes.
* Added support for puppetlabs-mysql 2.2 and greater.
* Added support for python-glanceclient v2 API update.
* Removed deprecated notifier_stratgy parameter.
* Deprecated show_image_direct_url in glance::rbd.

**3.1.0**

* Added availability to configure show_image_direct_url.
* Removed Keystone client warnings.
* Added support for https authentication endpoints.
* Enabled ssl configuration for glance-registry.
* Explicitly sets default notifier strategy.

**3.0.0**

* Major release for OpenStack Havana.
* Fixed bug to ensure keystone endpoint is set before service starts.
* Added Cinder backend to image storage.
* Fixed qpid_hostname bug.

**2.2.0**

* Added syslog support.
* Added support for iso disk format.
* Fixed bug to allow support for rdb options in glance-api.conf.
* Fixed bug for rabbitmq options in notify::rabbitmq.
* Removed non-implemented glance::scrubber class.
* Various lint and bug fixes.

**2.1.0**

* Added glance-cache-cleaner and glance-cache-pruner.
* Added ceph/rdb support.
* Added retry for glance provider to account for service startup time.
* Added support for both file and swift backends.
* Fixed allowed_hosts/database access bug.
* Fixed glance_image type example.
* Removed unnecessary mysql::server dependency.
* Removed --silent-upload option.
* Removed glance-manage version_control.
* Pinned rabbit and mysql module versions.
* Various lint and bug fixes.

**2.0.0**

* Upstream is now part of stackfoge.
* Added postgresql support.
* Various cleanups and bug fixes.
