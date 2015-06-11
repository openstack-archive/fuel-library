openstacklib
============

5.0.0 - 2014.2.0 - Juno
#### Table of Contents

1. [Overview - What is the openstacklib module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with openstacklib](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The openstacklib module is a part of [Stackforge](https://github.com/stackforge),
an effort by the Openstack infrastructure team to provide continuous integration
testing and code review for Openstack and Openstack community projects not part
of the core software.  The module itself is used to expose common functionality
between Openstack modules as a library that can be utilized to avoid code
duplication.

Module Description
------------------

The openstacklib module is a library module for other Openstack modules to
utilize. A thorough description will be added later.

This module is tested in combination with other modules needed to build and
leverage an entire Openstack software stack.  These modules can be found, all
pulled together in the [openstack module](https://github.com/stackforge/puppet-openstack).

Setup
-----

### Installing openstacklib

    example% puppet module install puppetlabs/openstacklib

Usage
-----

### Classes and Defined Types

#### Defined type: openstacklib::db::mysql

The db::mysql resource is a library resource that can be used by nova, cinder,
ceilometer, etc., to create a mysql database with configurable privileges for
a user connecting from defined hosts.

Typically this resource will be declared with a notify parameter to configure
the sync command to execute when the database resource is changed.

For example, in heat::db::mysql you might declare:

```
::openstacklib::db::mysql { 'heat':
    password_hash => mysql_password($password),
    dbname        => $dbname,
    user          => $user,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
    notify        => Exec['heat-dbsync'],
  }
```

Some modules should ensure that the database is created before the service is
set up. For example, in keystone::db::mysql you would have:

```
::openstacklib::db::mysql { 'keystone':
    password_hash => mysql_password($password),
    dbname        => $dbname,
    user          => $user,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
    notify        => Exec['keystone-manage db_sync'],
    before        => Service['keystone'],
  }
```

** Parameters for openstacklib::db::mysql: **

#####`password_hash`
Password hash to use for the database user for this service;
string; required

#####`dbname`
The name of the database
string; optional; default to the $title of the resource, i.e. 'nova'

#####`user`
The database user to create;
string; optional; default to the $title of the resource, i.e. 'nova'

#####`host`
The IP address or hostname of the user in mysql_grant;
string; optional; default to '127.0.0.1'

#####`charset`
The charset to use for the database;
string; optional; default to 'utf8'

#####`collate`
The collate to use for the database;
string; optional; default to 'utf8_unicode_ci'

#####`allowed_hosts`
Additional hosts that are allowed to access this database;
array or string; optional; default to undef

#####`privileges`
Privileges given to the database user;
string or array of strings; optional; default to 'ALL'


#### Defined type: openstacklib::service_validation

The service_validation resource is a library resource that can be used by nova, cinder,
ceilometer, etc., to validate that a resource is actually up and running.

For example, in nova::api you might declare:

```
::openstacklib::service_validation { 'nova-api':
    command => 'nova list',
  }
```
This defined resource creates an exec-anchor pair where the anchor depends upon
the successful exec run.

** Parameters for openstacklib::service_validation: **

#####`command`
Command to run for validating the service;
string; required

#####`service_name`
The name of the service to validate;
string; optional; default to the $title of the resource, i.e. 'nova-api'

#####`path`
The path of the command to validate the service;
string; optional; default to '/usr/bin:/bin:/usr/sbin:/sbin'

#####`provider`
The provider to use for the exec command;
string; optional; default to 'shell'

#####`tries`
Number of times to retry validation;
string; optional; default to '10'

#####`try_sleep`
Number of seconds between validation attempts;
string; optional; default to '2'

### Types and Providers

#### Aviator

#####`Puppet::add_aviator_params`

The aviator type is not a real type, but it serves to simulate a mixin model,
whereby other types can call out to the Puppet::add\_aviator\_params method in
order to add aviator-specific parameters to themselves. Currently this adds the
auth parameter to the given type. The method must be called after the type is
declared, e.g.:

```puppet
require 'puppet/type/aviator'
Puppet::Type.newtype(:my_type) do
# ...
end
Puppet::add_aviator_params(:my_type)
```

#####`Puppet::Provider::Aviator`

The aviator provider is a parent provider intended to serve as a base for other
providers that need to authenticate against keystone in order to accomplish a
task.

**`Puppet::Provider::Aviator#authenticate`**

Either creates an authenticated session or sets up an unauthenticated session
with instance variables initialized with a token to inject into the next request.
It takes as arguments a set of authentication parameters as a hash and a path
to a log file. Puppet::Provider::Aviator#authencate looks for five different
possible methods of authenticating, in the following order:

1) Username and password credentials in the auth parameters
2) The path to an openrc file containing credentials to read in the auth
   parameters
3) A service token in the auth parameters
4) Environment variables set for the environment in which Puppet is running
5) A service token in /etc/keystone/keystone.conf. This option provides
   backwards compatibility with earlier keystone providers.

If the provider has password credentials, it can create an authenticated
session. If it only has a service token, it initializes an unauthenciated
session and a hash of session data that can be injected into a future request.

**`Puppet::Provider::Aviator#make_request`**

After creating a session, the make\_request method provides an interface that
providers can use to make requests without worrying about whether they have an
authenticated or unauthenticated session. It takes as arguments the
Aviator::Service it is making a request at (for example, keystone), a symbol for
the request (for example, :list\_tenants), and optionally a block to execute
that will set parameters for an update request.

Implementation
--------------

### openstacklib

openstacklib is a combination of Puppet manifest and ruby code to delivery
configuration and extra functionality through types and providers.

Limitations
-----------

* Limitations will be added as they are discovered.

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation

Contributors
------------

* https://github.com/stackforge/puppet-openstacklib/graphs/contributors

Versioning
----------

This module has been given version 5 to track the puppet-openstack modules. The
versioning for the puppet-openstack modules are as follows:

```
Puppet Module :: OpenStack Version :: OpenStack Codename
2.0.0         -> 2013.1.0          -> Grizzly
3.0.0         -> 2013.2.0          -> Havana
4.0.0         -> 2014.1.0          -> Icehouse
5.0.0         -> 2014.2.0          -> Juno
```

Release Notes
-------------

**5.0.0**

* This is the initial release of this module.
