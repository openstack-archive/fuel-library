horizon
=======

5.0.0 - 2014.2.0 - Juno

#### Table of Contents

1. [Overview - What is the horizon module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with horizon](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors - Those with commits](#contributors)
8. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The horizon module is a part of [Stackforge](https://github.com/stackforge), an effort by the Openstack infrastructure team to provide continuous integration testing and code review for Openstack and Openstack community projects not part of the core software.  The module its self is used to flexibly configure and manage the dashboard service for Openstack.

Module Description
------------------

The horizon module is a thorough attempt to make Puppet capable of managing the entirety of horizon.  Horizon is a fairly classic django application, which results in a fairly simply Puppet module.

This module is tested in combination with other modules needed to build and leverage an entire Openstack software stack.  These modules can be found, all pulled together in the [openstack module](https://github.com/stackforge/puppet-openstack).

Setup
-----

**What the horizon module affects**

* horizon, the dashboard service for Openstack.

### Installing horizon

    example% puppet module install puppetlabs/horizon

### Beginning with horizon

To utilize the horizon module's functionality you will need to declare multiple resources but you'll find that doing so is much less complicated than the other OpenStack component modules.  The following is a modified excerpt from the [openstack module](https://github.com/stackforge/puppet-openstack).  We recommend you consult and understand the [openstack module](https://github.com/stackforge/puppet-openstack) and the [core openstack](http://docs.openstack.org) documentation.

**Define a horizon dashboard**

```puppet
class { 'memcached':
  listen_ip => '127.0.0.1',
  tcp_port  => '11211',
  udp_port  => '11211',
}

class { '::horizon':
  cache_server_ip       => '127.0.0.1',
  cache_server_port     => '11211',
  secret_key            => '12345',
  swift                 => false,
  django_debug          => 'True',
  api_result_limit      => '2000',
}
```

Implementation
--------------

### horizon

Horizon is a simple module using the combination of a package, template, and the file_line type.  Most all the configuration lives inside the included local_settings template and the file_line type is for selectively inserting needed lines into configuration files that aren't explicitly managed by the horizon module.

Limitations
------------

* Only supports Apache using mod_wsgi.

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation

Contributors
------------

* https://github.com/stackforge/puppet-horizon/graphs/contributors

Release Notes
-------------

**5.0.0**

* Stable Juno release
* Fixed the default value of compress_offline parameter
* Always manages local_settings.py
* Added parameters to configure policy files in horizon class
* Fixed Apache config file default
* Added parameter django_session_engine to horizon class
* Stops setting wsgi_socket_prefix since the apache module takes care of it
* Adds workaround for puppet's handling of undef for setting the vhost bind address
* Changes cache_server_ip in horizon class to accept arrays
* Switched the default log level to INFO from DEBUG
* Fixed the default MSSQL port in security group rules

**4.2.0**

* Added parameters to configure ALLOWED_HOSTS in settings_local.y and
  ServerAlias in apache, no longer requiring these values to be the fqdn
* Fixed removal of vhost conf file
* Added support for secure cookies

**4.1.0**

* Added option to set temporary upload directory for images.
* Ensure ssl wsgi_process_group is the same as wsgi_daemon_process.
* Pined major gems.

**4.0.0**

* Stable Icehouse release.
* Added support to pass extra parameters to vhost.
* Added support to ensure online cache is present and can be refreshed.
* Added support to configure OPENSTACK_HYPERVISOR_FEATURES settings, AVAILABLE_REGIONS, OPENSTACK_NEUTRON_NETWORK.
* Added support to disable configuration of Apache.
* Fixed log ownership and WSGIProcess* settings for Red Hat releases.
* Fixed overriding of policy files in local settings.
* Fixed SSL bugs.
* Improved WSGI configuration.

**3.1.0**

* Added option parameterize OPENSTACK_NEUTRON_NETWORK settings.

**3.0.1**

* Adds COMPRESS_OFFLINE option to local_settings to fix broken Ubuntu installation.

**3.0.0**

* Major release for OpenStack Havana.
* Updated user and group for Debian family OSes.
* Updated policy files for RedHat family OSes.
* Enabled SSL support with cert/key.
* Improved default logging configuration.
* Fixed bug to set LOGOUT_URL properly.
* Introduced new parameters: keystone_url, help_url, endpoint type.
* Fixed user/group regression for Debian.
* Changed keystone_default_role to _member_.

**2.2.0**

* Fixed apache 0.9.0 incompatability.
* Various lint fixes.

**2.1.0**

* Updated local_settings.py.
* Pinned Apache module version.
* Various lint fixes.

**2.0.0**

* Upstream is now part of stackforge.
* httpd config now managed on every platform.
* Provides option to enable Horizon's display of block device mount points.

