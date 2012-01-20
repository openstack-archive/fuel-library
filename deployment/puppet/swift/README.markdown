==Disclaimer

This is not ready to be used.

This is pre-beta code that is actively being developed.

It is currently being developed against swift trunk.

I am actively seeking users who understand that this code
is in a pre-alpha state. Feel free to contact me (Dan Bode)
at dan < at > puppetlabs <dot> com or bodepd < on > freenode.

Any feedback greatly appreciated.

==Dependencies

This module has the following dependencies:

  https://github.com/bodepd/puppet-ssh
    (this should actaully depend on https://github.com/saz/puppet-ssh
     and can when pull request https://github.com/saz/puppet-ssh/pull/1
     is merged)
  https://github.com/bodepd/puppet-rsync
    (there is a pull request to merge this into the parent repo:
    https://github.com/bodepd/puppet-rsync)
  https://github.com/saz/puppet-memcached
  https://github.com/puppetlabs/puppetlabs-stdlib

  This module has only been tested on Ubuntu Natty, with Puppet 2.7.9

this module is intended to complement other openstack modules and
will eventually be a submodule of the openstack set of modules:

  https://github.com/puppetlabs/puppetlabs-openstack

  These modules have only been verified as working against the
  Swift all in one installation instructions: http://swift.openstack.org/development_saio.html

  They have also only been tested for 1.4.6 (and will probably not work for Diablo... yet)

==Usage:

  swift:

    class that sets up base packages and the base
    /etc/swift/swift.conf.

    class { 'swift':
      # shared salt used when hashing ring mappings
      swift_hash_suffix => 'shared_secret',
    }

  swift::proxy:

    class that installs and configures the swift
    proxy server

    class { 'swift::proxy':
      # specifies that account should be automatically created
      account_autocreate = true,
      #proxy_local_net_ip = '127.0.0.1',
      #proxy_port = '11211',
      # auth type defaults to tempauth - this is the
      # only auth that has been tested
      #auth_type = 'tempauth',
    }

  swift::storage

    class that sets up all of the configuration and dependencies
    for swift storage instances

    class { 'swift::storage':
      # address that swift should bind to
      storage_local_net_ip => '127.0.0.1'
    }

  swift::storage::device

    defined resource type that can be used to
    indicate a specific device to be managed

    This will configure the rsync server instance
    and swift storage instance to manage the device (which
    basically maps port to device)

    # the title for this device is the port where it
    # will be hosted
    swift::storage::device { '6010'
      # the type of device (account/object/container)
      type => 'object',
      # directory where device is mounted
      devices = '/srv/node',
      # address to bind to
      storage_local_net_ip = '127.0.0.1'
    ) {

  swift::storage::loopback

    This defined resource was created to test
    swift by creating loopback devices that can be
    used for testing

    It creates a partition of size [$seek]
    at base_dir/[$name] using dd with [$byte_size],
    formats it to be an xfs
    filesystem which is mounted at /src/node/[$name]

    It then creates swift::storage::devices for each device
    type using the title as the 3rd digit of
    a four digit port number

      60[digit][role] (object = 0, container = 1, account = 2)

    swift::storage::loopback { '1':
      base_dir  = '/srv/loopback-device',
      mnt_base_dir = '/srv/node',
      byte_size = '1024',
      seek      = '25000',
      storage_local_net_ip = '127.0.0.1'
    }

  swift::ringbuiler

   class that knows how to build rings. This only exists as a vague idea

  the ring building will like be built as a combination of native types
  (for adding the drives) and defined types for rebalancing

==Example

For an example of how to use this module to build out a single node
swift cluster, you can try running puppet apply examples/site.pp
(feel free to look at the code to see how to use this module)

There are a few known issues with this code:

  - for some reason the ringbuilding script does not run
    after the manifest fails, you still need to login
    and run bash /etc/swift/ringbuilder.sh and start swift-proxy
  - once swift is running, you can test the swift instance with the
    ruby script stored in files/swift_tester.rb

This example can be used as follows:

puppet apply examples/site.pp --certname pre_swift

puppet apply examples/site.pp --certname swift_all
