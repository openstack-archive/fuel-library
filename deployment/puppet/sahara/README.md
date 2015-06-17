sahara
======

#### Table of Contents

1. [Overview - What is the sahara module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with sahara](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The Sahara module itself is used to flexibly configure and manage the
clustering service for OpenStack.

Module Description
------------------

The sahara module is an attempt to make Puppet capable of managing the
entirety of sahara.

Setup
-----

**What the sahara module affects:**

* sahara, the data processing service for OpenStack.

### Beginning with sahara

To use the sahara module's functionality you will need to declare multiple
resources.  This is not an exhaustive list of all the components needed; we
recommend you consult and understand the
[core of openstack](http://docs.openstack.org) documentation.

Examples of usage can be found in the *examples* directory.

Implementation
--------------

### sahara

puppet-sahara is a combination of Puppet manifests and ruby code to deliver
configuration and extra functionality through types and providers.

Limitations
-----------

None.

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

* https://github.com/stackforge/puppet-sahara/graphs/contributors

Release Notes
-------------

**5.0.0**

* Rewrite
