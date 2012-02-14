# Disclaimer #

This is pre-beta code that is actively being developed.

Although the code is in a functional state, there is currently
no guarentees about the interfaces that it provides.

I am actively seeking users who understand that this code
is in a pre-alpha state. Feel free to contact me (Dan Bode)
at dan@puppetlabs.com or bodepd<on>freenode.

Any feedback greatly appreciated.

# Use Cases #

* Tested for a single node swift install
    http://swift.openstack.org/development_saio.html

* Tested for multi-node swift install
   http://swift.openstack.org/howto_installmultinode.html

* Only been tested with tempauth

# Dependencies: #

* Only tested on Ubuntu Natty
* Only tested against Puppet 2.7.10
* Only verified with Swift 1.4.7

# module Dependencies #

This is known to work with master from the following github repos:

* https://github.com/saz/puppet-ssh
* https://github.com/puppetlabs/puppetlabs-rsync
* https://github.com/saz/puppet-memcached
* https://github.com/puppetlabs/puppetlabs-stdlib

This module is intended to complement other openstack modules and
will eventually be a submodule of the openstack set of modules:

  https://github.com/puppetlabs/puppetlabs-openstack

# Usage: #

## swift: ##

class that sets up base packages and the base
/etc/swift/swift.conf.

    class { 'swift':
      # shared salt used when hashing ring mappings
      swift_hash_suffix => 'shared_secret',
    }

## swift::proxy: ##

class that installs and configures the swift
proxy server

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

class that sets up all of the configuration and dependencies
for swift storage server instances

    class { 'swift::storage':
      # address that swift should bind to
      storage_local_net_ip => $ipaddress_eth1,
      devices              => '/srv/node'
    }

## swift::storage::server ##

Defined resource type that can be used to
create a swift storage server instance. In general, you do
not need to explicity specify your server instances (as the
swift::storage::class will create them for you)

This will configure an rsync server instance
and swift storage instance to manage the all devices in
the devices directory.

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

This defined resource was created to test
swift by creating loopback devices that can be
used for testing

It creates a partition of size [$seek]
at base_dir/[$name] using dd with [$byte_size],
formats it to be an xfs
filesystem which is mounted at /src/node/[$name]

It then creates swift::storage::devices for each device
type using the title as the 3rd digit of
a four digit port number :60[digit][role] (object = 0, container = 1, account = 2)

    swift::storage::loopback { '1':
      base_dir  => '/srv/loopback-device',
      mnt_base_dir => '/srv/node',
      byte_size => '1024',
      seek      => '25000',
      storage_local_net_ip => '127.0.0.1'
}

## swift::ringbuiler ##

class that knows how to build rings.

Creates the initial rings, collects any exported resources,
and rebalances the ring if it is updated.

      class { 'swift::ringbuilder':
        part_power     => '18',
        replicas       => '3',
        min_part_hours => '1',
      }

# Example #

For an example of how to use this module to build out a single node
swift cluster, you can have a look at examples/all.pp

This example can be used as follows:`

  # set up pre-reqs
  puppet apply examples/pre.pp

  # install all swift components on a single node
  puppet apply examples/all.pp

For an example of how to use this module to build out a multi node
swift cluster, you can have a look at examples/multi.pp

This example assumes that a puppetmaster already exists and is
resolvable as puppetmaster.

This example can be used as follows:`

  # set up pre-reqs
  puppet apply examples/pre.pp

  # install all swift components on a single node
  puppet apply examples/all.pp --certname my_role

# Verifying installation #

This module also comes with a simple Ruby script that validates
rather or not your swift cluster is functional.

The script can be run as:

  ruby /files/swift_tester.rb

