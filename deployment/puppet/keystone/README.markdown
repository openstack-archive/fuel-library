# Overview #

The module contains a collection of manifests and native types that are capable
of installing/managing/configuring Keystone.

Keystone is the Identity service for OpenStack.

# Tested use cases #

This module has been tested against the dev version of Ubuntu Precise.

It has only currently been tested as a single node installation of keystone.

It is currently targetting essex support and is being actively developed against
packaging that are built off of trunk.

# Dependencies: #

This module has relatively few dependencies:

  https://github.com/puppetlabs/puppet-concat
  # if used on Ubuntu
  https://github.com/puppetlabs/puppet-apt
  # if using mysql as a backend
  https://github.com/puppetlabs/puppetlabs-mysql

# Usage #
## Manifests ##

### class keystone ###

The keystone class sets up the basic configuration for the keystone service.

It must be used together with a class that expresses the db backend to use:

for example:

    class { 'keystone':
      verbose => true,
      admin_token => 'my_secret_token'
    }

  needs to be configured to use a backend database with either:

    class { 'keystone::config::sqlite': }

  or

    class { 'keystone::config::mysql':
      password => 'keystone',
    }
  or

    class { 'keystone::config::postgresql':
      password => 'keystone',
    }

### setting up a keystone mysql db ###

  A keystone mysql database can be configured separately from
  the service.

  If you need to actually install a mysql database server, you can use
  the mysql::server class from the puppetlabs mysql module

    # check out the mysql module's README to learn more about
    # how to more appropriately configure a server
    class { 'mysql::server': }

    class { 'keystone::mysql':
      dbname   => 'keystone',
      user     => 'keystone',
      password => 'keystone_password',
    }

### setting up a keystone postgresql db ###

  A keystone postgresql database can be configured separately from
  the service instead of mysql.

  If you need to actually install a postgresql database server, you can use
  the postgresql::server class from the puppetlabs postgresql module. You
  will also need that module to install the postgresql python driver dependencies.

  # check out the postgresql module's README to learn more about
  # how to more appropriately configure a server
  class { 'postgresql::server': }

  class { 'keystone::postgresql':
      dbname   => 'keystone',
      user     => 'keystone',
      password => 'keystone_password',
  }

## Native Types ##

  The Puppet support for keystone also includes native types that can be
  used to manage the following keystone objects:

    - keystone_tenant
    - keystone_user
    - keystone_role
    - keystone_user_role
    - keystone_service
    - keystone_endpoint

  These types will only work on an actual keystone node (and they read keystone.conf
  to figure out the admin port and admin token, which is kind of hacky, but the best
  way I could think of.)

    - keystone_config - manages individual config file entries as resources.

### examples ###

  keystone_tenant { 'openstack':
    ensure  => present,
    enabled => 'True',
  }
  keystone_user { 'openstack':
    ensure  => present,
    enabled => 'True'
  }
  keystone_role { 'admin':
    ensure => present,
  }
  keystone_user_role { 'admin@openstack':
    roles => ['admin', 'superawesomedue'],
    ensure => present
  }

### puppet resource ###

These native types also allow for some interesting introspection using puppet resource

To list all of the objects of a certain type in the keystone database, you can run:

  puppet resource <type>

For example:

  puppet resource keystone_tenant

  would list all know keystone tenants for a given keystone instance.
