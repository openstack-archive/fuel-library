keystone
=======

6.0.0 - 2015.1 - Kilo

#### Table of Contents

1. [Overview - What is the keystone module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with keystone](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)

Overview
--------

The keystone module is a part of [OpenStack](https://github.com/openstack), an effort by the Openstack infrastructure team to provide continuous integration testing and code review for Openstack and Openstack community projects as part of the core software.  The module its self is used to flexibly configure and manage the identify service for Openstack.

Module Description
------------------

The keystone module is a thorough attempt to make Puppet capable of managing the entirety of keystone.  This includes manifests to provision region specific endpoint and database connections.  Types are shipped as part of the keystone module to assist in manipulation of configuration files.

This module is tested in combination with other modules needed to build and leverage an entire Openstack software stack.  These modules can be found, all pulled together in the [openstack module](https://github.com/stackfoge/puppet-openstack).

Setup
-----

**What the keystone module affects**

* keystone, the identify service for Openstack.

### Installing keystone

    example% puppet module install puppetlabs/keystone

### Beginning with keystone

To utilize the keystone module's functionality you will need to declare multiple resources.  The following is a modified excerpt from the [openstack module](https://github.com/stackfoge/puppet-openstack).  This is not an exhaustive list of all the components needed, we recommend you consult and understand the [openstack module](https://github.com/stackforge/puppet-openstack) and the [core openstack](http://docs.openstack.org) documentation.

**Define a keystone node**

```puppet
class { 'keystone':
  verbose             => True,
  catalog_type        => 'sql',
  admin_token         => 'random_uuid',
  database_connection => 'mysql://keystone_admin:super_secret_db_password@openstack-controller.example.com/keystone',
}

# Adds the admin credential to keystone.
class { 'keystone::roles::admin':
  email        => 'admin@example.com',
  password     => 'super_secret',
}

# Installs the service user endpoint.
class { 'keystone::endpoint':
  public_url   => 'http://10.16.0.101:5000/v2.0',
  admin_url    => 'http://10.16.1.101:35357/v2.0',
  internal_url => 'http://10.16.2.101:5000/v2.0',
  region       => 'example-1',
}
```

**Leveraging the Native Types**

Keystone ships with a collection of native types that can be used to interact with the data stored in keystone.  The following, related to user management could live throughout your Puppet code base.  They even support puppet's ability to introspect the current environment much the same as `puppet resource user`, `puppet resouce keystone_tenant` will print out all the currently stored tenants and their parameters.

```puppet
keystone_tenant { 'openstack':
  ensure  => present,
  enabled => True,
}
keystone_user { 'openstack':
  ensure  => present,
  enabled => True,
}
keystone_role { 'admin':
  ensure => present,
}
keystone_user_role { 'admin@openstack':
  roles => ['admin', 'superawesomedude'],
  ensure => present
}
```

These two will seldom be used outside openstack related classes, like nova or cinder.  These are modified examples form Class['nova::keystone::auth'].

```puppet
# Setup the nova keystone service
keystone_service { 'nova':
  ensure      => present,
  type        => 'compute',
  description => 'Openstack Compute Service',
}

# Setup nova keystone endpoint
keystone_endpoint { 'example-1-west/nova':
   ensure       => present,
   public_url   => "http://127.0.0.1:8774/v2/%(tenant_id)s",
   admin_url    => "http://127.0.0.1:8774/v2/%(tenant_id)s",
   internal_url => "http://127.0.0.1:8774/v2/%(tenant_id)s",
}
```

**Setting up a database for keystone**

A keystone database can be configured separately from the keystone services.

If one needs to actually install a fresh database they have the choice of mysql or postgres.  Use the mysql::server or postgreql::server classes to do this setup then the Class['keystone::db::mysql'] or Class['keystone::db::postgresql'] for adding the needed databases and users that will be needed by keystone.

* For mysql

```puppet
class { 'mysql::server': }

class { 'keystone::db::mysql':
  password      => 'super_secret_db_password',
  allowed_hosts => '%',
}
```

* For postgresql

```puppet
class { 'postgresql::server': }

class { 'keystone::db::postgresql': password => 'super_secret_db_password', }
```

Implementation
--------------

### keystone

keystone is a combination of Puppet manifest and ruby code to delivery configuration and extra functionality through types and providers.

Limitations
------------

* All the keystone types use the CLI tools and so need to be ran on the keystone node.

### Upgrade warning

* If you've setup Openstack using previous versions of this module you need to be aware that it used UUID as the dedault to the token_format parameter but now defaults to PKI.  If you're using this module to manage a Grizzly Openstack deployment that was set up using a development release of the modules or are attempting an upgrade from Folsom then you'll need to make sure you set the token_format to UUID at classification time.

Beaker-Rspec
------------

This module has beaker-rspec tests

To run:

``shell
bundle install
bundle exec rspec spec/acceptance
``

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation

Contributors
------------

* https://github.com/openstack/puppet-keystone/graphs/contributors
