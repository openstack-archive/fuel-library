puppet-heat
=============

6.0.0 - 2015.1 - Kilo

#### Table of Contents

1. [Overview - What is the heat module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with heat](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)

Overview
--------

The heat module is part of [OpenStack](https://github.com/openstack), an effort by the
OpenStack infrastructure team to provice continuous integration testing and code review for
OpenStack and OpenStack community projects as part of the core software. The module itself
is used to flexibly configure and manage the orchestration service for OpenStack.

Module Description
------------------

The heat module is an attempt to make Puppet capable of managing the entirety of heat.

Setup
-----

**What the heat module affects**

* heat, the orchestration service for OpenStack

### Installing heat 

  example% puppet module install puppetlabs/heat

### Beginning with heat

Implementation
--------------

### puppet-heat

heat is a combination of Puppet manifests and Ruby code to deliver configuration and
extra functionality through types and providers.

Limitations
-----------

None

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

* https://github.com/openstack/puppet-heat/graphs/contributors
