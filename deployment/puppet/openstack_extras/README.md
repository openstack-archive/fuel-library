openstack_extras
============

#### Table of Contents

1. [Overview - What is the openstack_extras module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with openstack_extras](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The openstack_extras module is a part of [Stackforge](https://github.com/stackforge),
an effort by the Openstack infrastructure team to provide continuous integration
testing and code review for Openstack and Openstack community projects not part
of the core software.  The module itself is used to add useful utilities for
composing and deploying OpenStack with the Stackforge Openstack modules.

Module Description
------------------

The openstack_extras module is intended to provide useful utilities to help
with OpenStack deployments, including composition classes, HA utilities,
monitoring functionality, and so on.

This module combines other modules in order to build and leverage an entire
OpenStack software stack. This module replaces functionality from the
deprecated [stackforge/puppet-openstack module](https://github.com/stackforge/puppet-openstack).

Setup
-----

### Installing openstack_extras

    example% puppet module install puppetlabs/openstack_extras

### Beginning with openstack_extras

Instructions for beginning with openstack_extras will be added later.

Implementation
--------------

### openstack_extras

openstack_extras is a combination of Puppet manifest and ruby code to delivery
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

* https://github.com/stackforge/puppet-openstack_extras/graphs/contributors

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
