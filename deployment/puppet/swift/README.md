# Introduction

This module provides a way to install and configure Swift storage clusters using
puppet. The classes documented in this file will deploy Swift using best
practices for a typical deployment.

Both single host and clustered configurations are supported.

## Tested Environments
  * Ubuntu 12.04; puppet 2.7.16; Swift 1.4.8

# Dependencies

* https://github.com/saz/puppet-ssh
* https://github.com/puppetlabs/puppetlabs-rsync
* https://github.com/saz/puppet-memcached
* https://github.com/puppetlabs/puppetlabs-stdlib

# Usage: #

## swift: ##

class that sets up base packages and the base /etc/swift/swift.conf.

    class { 'swift':
      # shared salt used when hashing ring mappings
      swift_hash_suffix => 'shared_secret',
    }

## swift::proxy: ##

class that installs and configures the swift proxy server

    class { 'swift::proxy':
      # specifies that account should be automatically created
      # this should be set to true when tempauth is used
      account_autocreate = true,
      proxy_local_net_ip = $ipaddress_eth1,
      #proxy_port = '11211',
      # auth type defaults to tempauth - this is the
      # only auth that has been tested
      #auth_type = 'tempauth',
    }

## swift::storage ##

class that sets up all of the configuration and dependencies for swift storage
server instances

    class { 'swift::storage':
      # address that swift should bind to
      storage_local_net_ip => $ipaddress_eth1,
      devices              => '/srv/node'
    }

## swift::storage::server ##

Defined resource type that can be used to create a swift storage server
instance. In general, you do not need to explicity specify your server instances
(as the swift::storage::class will create them for you)

This will configure an rsync server instance and swift storage instance to
manage the all devices in the devices directory.

    # the title for this server and the port where it
    # will be hosted
    swift::storage::server { '6010':
      # the type of device (account/object/container)
      type => 'object',
      # directory where device is mounted
      devices => '/srv/node',
      # address to bind to
      storage_local_net_ip => '127.0.0.1'
    }

## swift::storage::loopback ##

This defined resource was created to test swift by creating loopback devices
that can be used for testing

It creates a partition of size [$seek] at base_dir/[$name] using dd with
[$byte_size], formats it to be an xfs filesystem which is mounted at
[$mnt_base_dir]/[$name]

It then creates swift::storage::devices for each device type using the title as
the 3rd digit of a four digit port number :60[digit][role] (object = 0,
container = 1, account = 2)

    swift::storage::loopback { '1':
      base_dir  => '/srv/loopback-device',
      mnt_base_dir => '/srv/node',
      byte_size => '1024',
      seek      => '25000',
      storage_local_net_ip => '127.0.0.1'
}

## swift::ringbuiler ##

class that knows how to build rings.

Creates the initial rings, collects any exported resources, and rebalances the
ring if it is updated.

      class { 'swift::ringbuilder':
        part_power     => '18',
        replicas       => '3',
        min_part_hours => '1',
      }

# Example #

For an example of how to use this module to build out a single node swift
cluster, you can have a look at examples/all.pp

This example can be used as follows:

    puppet apply examples/all.pp

For an example of how to use this module to build out a multi node swift
cluster, you can have a look at examples/site.pp. This file assumes you have a
puppetmaster with storeconfigs enabled.

Please note that if you create fewer than 3 storage nodes, you will need to edit
the `replicas` parameter of the swift::ringbuilder instance in the proxy node
definition.

Once your puppetmaster is configured, you can provision your nodes with:

    puppet agent -t --certname my_role

# Verifying installation #

This module also comes with a simple Ruby script that validates rather or not
your swift cluster is functional.

The script can be run as:

    ruby files/swift_tester.rb
