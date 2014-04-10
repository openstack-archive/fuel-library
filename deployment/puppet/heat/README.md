puppet-heat
=============

4.0.0 - 2014.1.0 - Icehouse

#### Table of Contents

1. [Overview - What is the heat module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with heat](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The heat module is part of [Stackforge](https://github.com/stackforge), an effort by the
OpenStack infrastructure team to provice continuous integration testing and code review for
OpenStack and OpenStack community projects not part of the core software. The module itself
is used to flexibly configure and manage the orchestration service for OpenStack

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

The Heat Openstack service depends on a sqlalchemy database. If you are using puppetlabs-mysql to achieve this, there is a parameter called mysql_module that can be used to swap between the two supported versions: 0.9 and 2.2. This is needed because the puppetlabs-mysql module was rewritten and the custom type names have changed between versions.

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation

Contributors
------------

* https://github.com/stackforge/puppet-heat/graphs/contributors

Release Notes
-------------

**4.0.0**

* Stable Icehouse release.
* Added SSL parameter for RabbitMQ.
* Added support for puppetlabs-mysql 2.2 and greater.
* Added option to define RabbitMQ queues as durable.
* Fixed outdated DB connection parameter.
* Fixed Keystone auth_uri parameter.

**3.1.0**

* Fixed postgresql connection string.
* Allow log_dir to be set to false to disable file logging.
* Added support for database idle timeout.
* Aligned Keystone auth_uri with other OpenStack services.
* Fixed the EC2 auth token settings.
* Fixed rabbit_virtual_host configuration.

**3.0.0**

* Initial release of the puppet-heat module.

License
-------

Apache License 2.0

   Copyright 2012 eNovance <licensing@enovance.com> and Authors

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

Contact
-------

techs@enovance.com
