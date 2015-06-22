keystone
=======

5.1.0 - 2014.2 - Juno

#### Table of Contents

1. [Overview - What is the keystone module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with keystone](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The keystone module is a part of [Stackforge](https://github.com/stackfoge), an effort by the Openstack infrastructure team to provide continuous integration testing and code review for Openstack and Openstack community projects not part of the core software.  The module its self is used to flexibly configure and manage the identify service for Openstack.

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

* https://github.com/stackforge/puppet-keystone/graphs/contributors

Release Notes
-------------

**5.1.0**

* Allow disabling or delaying the token_flush cron
* crontab: ensure the script is run with shell
* Use openstackclient for keystone_* providers
* Add lib directories to $LOAD_PATH if not present
* Remove keystone.rb provider for keystone_endpoint
* Add timeout to API requests
* Test keystone_user password with Net::HTTP
* service_identity: add user/role ordering
* Fix password check for SSL endpoints
* add require json for to_json dependency
* spec: pin rspec-puppet to 1.0.1
* Switch to TLSv1
* handle missing project/tenant when using ldap backend
* Add support for LDAP connection pools
* Sync keystone.py with upstream to function with Juno
* Create resource cache upon creation
* Implement caching lookup for keystone_user_role
* Remove warnings from openstack responses
* Properly handle embedded newlines in csv
* support the ldap user_enabled_invert parameter
* Shorten HTTP request timeout length
* Tag packages with 'openstack'
* Allow Keystone to be queried when using IPv6 ::0
* Add ::keystone::policy class for policy management
* New option replace_password for keystone_user
* Pin puppetlabs-concat to 1.2.1 in fixtures
* Set WSGI process display-name
* Rename resource instance variable
* Add native types for keystone paste configuration
* Update .gitreview file for project rename

**5.0.0**

* Stable Juno release
* Updated token driver, logging, and ldap config parameters for Juno
* Changed admin_roles parameter to accept an array in order to configure multiple admin roles
* Installs python-ldappool package for ldap
* Added new parameters to keystone class to configure pki signing
* Changed keystone class to inherit from keystone::params
* Changed pki_setup to run regardless of token provider
* Made UUID the default token provider
* Made keystone_user_role idempotent
* Added parameters to control whether to configure users
* Stopped managing _member_ role since it is created automatically
* Stopped overriding token_flush log file
* Changed the usage of admin_endpoint to not include the API version
* Allowed keystone_user_role to accept email as username
* Added ability to set up keystone using Apache mod_wsgi
* Migrated the keystone::db::mysql class to use openstacklib::db::mysql and deprecated the mysql_module parameter
* Installs python-memcache when using token driver memcache
* Enabled setting cert and key paths for PKI token signing
* Added parameters for SSL communication between keystone and rabbitmq
* Added parameter ignore_default_tenant to keystone::role::admin
* Added parameter service_provider to keystone class
* Added parameters for service validation to keystone class

**4.2.0**

* Added class for extended logging options
* Fixed rabbit password leaking
* Added parameters to set tenant descriptions
* Fixed keystone user authorization error handling

**4.1.0**

* Added token flushing with cron.
* Updated database api for consistency with other projects.
* Fixed admin_token with secret parameter.
* Fixed deprecated catalog driver.

**4.0.0**

* Stable Icehouse release.
* Added template_file parameter to specify catalog.
* Added keystone::config to handle additional custom options.
* Added notification parameters.
* Added support for puppetlabs-mysql 2.2 and greater.
* Fixed deprecated sql section header in keystone.conf.
* Fixed deprecated bind_host parameter.
* Fixed example for native type keystone_service.
* Fixed LDAP module bugs.
* Fixed variable for host_access dependency.
* Reduced default token duration to one hour.

**3.2.0**

* Added ability to configure any catalog driver.
* Ensures log_file is absent when using syslog.

**3.1.1**

* Fixed inconsistent variable for mysql allowed hosts.

**3.1.0**

* Added ability to disable pki_setup.
* Load tenant un-lazily if needed.
* Add log_dir param, with option to disable.
* Updated endpoint argument.
* Added support to enable SSL.
* Removes setting of Keystone endpoint by default.
* Relaxed regex when keystone refuses connections.

**3.0.0**

* Major release for OpenStack Havana.
* Fixed duplicated keystone endpoints.
* Refactored keystone_endpoint to use prefetch and flush paradigm.
* Switched from signing/format to token/provider.
* Created memcache_servers option to allow for multiple cache servers.
* Enabled serving Keystone from Apache mod_wsgi.
* Moved db_sync to its own class.
* Removed creation of Member role.
* Improved performance of Keystone providers.
* Updated endpoints to support paths and ssl.
* Added support for token expiration parameter.

**2.2.0**

* Optimized tenant and user queries.
* Added syslog support.
* Added support for token driver backend.
* Various bug and lint fixes.

**2.1.0**

* Tracks release of puppet-quantum
* Fixed allowed_hosts contitional statement
* Pinned depedencies
* Select keystone endpoint based on SSL setting
* Improved tenant_hash usage in keystone_tenant
* Various cleanup and bug fixes.

**2.0.0**

* Upstream is now part of stackfoge.
* keystone_user can be used to change passwords.
* service tenant name now configurable.
* keystone_user is now idempotent.
* Various cleanups and bug fixes.
