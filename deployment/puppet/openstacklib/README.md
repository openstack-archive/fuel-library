openstacklib
============

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

**5.0.0-devel**

* This is the initial release of this module.
