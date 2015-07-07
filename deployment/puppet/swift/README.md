swift
=======

5.1.0 - 2014.2 - Juno

#### Table of Contents

1. [Overview - What is the swift module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with swift](#setup)
4. [Reference - The classes, defines,functions and facts available in this module](#reference)
5. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)
8. [Contributors - Those with commits](#contributors)

Overview
--------

The swift module is a part of [OpenStack](https://github.com/openstack), an effort by the Openstack infrastructure team to provide continuous integration testing and code review for Openstack and Openstack community projects as part of the core software.  The module itself is used to flexibly configure and manage the object storage service for Openstack.

Module Description
------------------

The swift module is a thorough attempt to make Puppet capable of managing the entirety of swift.  This includes manifests to provision such things as keystone, storage backends, proxies, and the ring.  Types are shipped as part of the swift module to assist in manipulation of configuration files.  The classes in this module will deploy Swift using best practices for a typical deployment.

This module is tested in combination with other modules needed to build and leverage an entire Openstack software stack.  These modules can be found, all pulled together in the [openstack module](https://github.com/stackforge/puppet-openstack).  In addition, this module requires Puppet's [exported resources](http://docs.puppetlabs.com/puppet/3/reference/lang_exported.html).

Setup
-----

**What the swift module affects**

* swift, the object storage service for Openstack.

### Installing swift

    example% puppet module install puppetlabs/swift

### Beginning with swift

You much first setup [exported resources](http://docs.puppetlabs.com/puppet/3/reference/lang_exported.html).

To utilize the swift module's functionality you will need to declare multiple resources.  The following is a modified excerpt from the [openstack module](https://github.com/stackforge/puppet-openstack).  This is not an exhaustive list of all the components needed, we recommend you consult and understand the [openstack module](https://github.com/stackforge/puppet-openstack) and the [core openstack](http://docs.openstack.org) documentation.

**Defining a swift storage node**

```puppet
class { 'swift':
  swift_hash_suffix => 'swift_secret',
}

swift::storage::loopback { ['1', '2']:
 require => Class['swift'],
}

class { 'swift::storage::all':
  storage_local_net_ip => $ipaddress_eth0
}

@@ring_object_device { "${ipaddress_eth0}:6000/1":
  region => 1, # optional, defaults to 1
  zone   => 1,
  weight => 1,
}
@@ring_container_device { "${ipaddress_eth0}:6001/1":
  zone   => 1,
  weight => 1,
}
@@ring_account_device { "${ipaddress_eth0}:6002/1":
  zone   => 1,
  weight => 1,
}

@@ring_object_device { "${ipaddress_eth0}:6000/2":
  region => 2,
  zone   => 1,
  weight => 1,
}
@@ring_container_device { "${ipaddress_eth0}:6001/2":
  region => 2,
  zone   => 1,
  weight => 1,
}
@@ring_account_device { "${ipaddress_eth0}:6002/2":
  region => 2,
  zone   => 1,
  weight => 1,
}

Swift::Ringsync<<||>>
```

Usage
-----

### Class: swift

Class that will set up the base packages and the base /etc/swift/swift.conf

```puppet
class { 'swift': swift_hash_suffix => 'shared_secret', }
```

####`swift_hash_suffix`
The shared salt used when hashing ring mappings.

### Class swift::proxy

Class that installs and configures the swift proxy server.

```puppet
class { 'swift::proxy':
  account_autocreate => true,
  proxy_local_net_ip => $ipaddress_eth1,
  port               => '11211',
}
```

####`account_autocreate`
Specifies if the module should manage the automatic creation of the accounts needed for swift.  This should be set to true if tempauth is also being used.

####`proxy_local_net_ip`
This is the ip that the proxy service will bind to when it starts.

####`port`
The port for which the proxy service will bind to when it starts.

### Class: swift::storage

Class that sets up all of the configuration and dependencies for swift storage server instances.

```puppet
class { 'swift::storage': storage_local_net_ip => $ipaddress_eth1, }
```

####`storage_local_net_ip`
This is the ip that the storage service will bind to when it starts.

### Class: swift::ringbuilder

A class that knows how to build swift rings.  Creates the initial ring via exported resources and rebalances the ring if it is updated.

```puppet
class { 'swift::ringbuilder':
  part_power     => '18',
  replicas       => '3',
  min_part_hours => '1',
}
```

####`part_power`
The number of partitions in the swift ring. (specified as the power of 2)

####`replicas`
The number of replicas to store.

####`min_part_hours`
Time before a partition can be moved.

### Define: swift::storage::server

Defined resource type that can be used to create a swift storage server instance.  If you keep the sever names unique it is possibly to create multiple swift servers on a single physical node.

This will configure an rsync server instance and swift storage instance to
manage the all devices in the devices directory.

```puppet
swift::storage::server { '6010':
  type                 => 'object',
  devices              => '/srv/node',
  storage_local_net_ip => '127.0.0.1'
}
```

####`namevar`
The namevar/title for this type will map to the port where the server is hosted.

####`type`
The type of device, e.g. account, object, or container.

####`device`
The directory where the physical storage device will be mounted.

####`storage_local_net_ip`
This is the ip that the storage service will bind to when it starts.

### Define: swift::storage::loopback

This defined resource type was created to test swift by creating a loopback device that can be used a storage device in the absent of a dedicated block device.

It creates a partition of size [`$seek`] at basedir/[`$name`] using dd with [`$byte_size`], formats is to be a xfs filesystem which is then mounted at [`$mnt_base_dir`]/[`$name`].

Then, it creates an instance of defined class for the xfs file system that will eventually lead the mounting of the device using the swift::storage::mount define.

```puppet
swift::storage::loopback { '1':
  base_dir  => '/srv/loopback-device',
  mnt_base_dir => '/srv/node',
  byte_size => '1024',
  seek      => '25000',
}
```

####`base_dir`
The directory where the flat files will be stored that house the file system to be loop back mounted.

####`mnt_base_dir`
The directory where the flat files that store the file system to be loop back mounted are actually mounted at.

####`byte_size`
The byte size that dd uses when it creates the file system.

####`seek`
The size of the file system that will be created.  Defaults to 25000.

### Verifying installation

This modules ships with a simple Ruby script that validates whether or not your swift cluster is functional.

The script can be run as:

`ruby $modulepath/swift/files/swift_tester.rb`

Implementation
--------------

### swift

swift is a combination of Puppet manifest and ruby code to delivery configuration and extra functionality through types and providers.

Limitations
------------

* No explicit support external NAS devices (i.e. Nexenta and LFS) to offload the ring replication requirements.

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

* https://github.com/openstack/puppet-swift/graphs/contributors
