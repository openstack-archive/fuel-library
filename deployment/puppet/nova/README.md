nova
====

6.0.0 - 2015.1 - Kilo

#### Table of Contents

1. [Overview - What is the nova module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with nova](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)

Overview
--------

The nova module is a part of [OpenStack](https://github.com/openstack), an effort by the Openstack infrastructure team to provide continuous integration testing and code review for Openstack and Openstack community projects as part of the core software.  The module its self is used to flexibly configure and manage the compute service for Openstack.

Module Description
------------------

The nova module is a thorough attempt to make Puppet capable of managing the entirety of nova.  This includes manifests to provision such things as keystone endpoints, RPC configurations specific to nova, and database connections.  Types are shipped as part of the nova module to assist in manipulation of configuration files.

This module is tested in combination with other modules needed to build and leverage an entire Openstack software stack.  These modules can be found, all pulled together in the [openstack module](https://github.com/openstack/puppet-openstack).

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

* https://github.com/openstack/puppet-nova/graphs/contributors
