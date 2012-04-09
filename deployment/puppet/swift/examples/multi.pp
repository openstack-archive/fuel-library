#
# Example file for building out a multi-node environment
#
# This example creates nodes of the following roles:
#   swift_storage - nodes that host storage servers
#   swift_proxy - nodes that serve as a swift proxy
#   swift_ringbuilder - nodes that are responsible for
#     rebalancing the rings
#
# This example assumes a few things:
#   * the multi-node scenario requires a puppetmaster
#   * it assumes that networking is correctly configured
#
# These nodes need to be brought up in a certain order
#
# 1. storage nodes
# 2. ringbuilder
# 3. run the storage nodes again (to synchronize the ring db)
#    TODO - the code for this has not been written yet...
# 4. run the proxy
# 5. test that everything works!!
#
# This example file is what I used for testing
# in vagrant
#
#
# simple shared salt
$swift_shared_secret='changeme'
# assumes that the ip address where all of the storage nodes
# will communicate is on eth1
$swift_local_net_ip = $ipaddress_eth0

Exec { logoutput => true }

stage { 'openstack_ppa':}

Stage['openstack_ppa'] -> Stage['main']

class { 'apt':
  stage => 'openstack_ppa',
}
class { 'swift::repo::trunk':
  stage => 'openstack_ppa',
}
#
# specifies that nodes with the cert names of
# swift_storage_1,2, and 3 will be assigned the
# role of swift_storage_nodes with in the respective
# zones of 1,2,3
#
node 'swift_storage_1' {

  $swift_zone = 1
  include role_swift_storage

}
node 'swift_storage_2' {

  $swift_zone = 2
  include role_swift_storage

}
node 'swift_storage_3' {

  $swift_zone = 3
  include role_swift_storage


}

#
# Specfies that a node with certname of swift_proxy
# will be assigned the role of swift proxy.
# In my testing environemnt, the proxy node also serves
# as the ringbuilder
#
node 'swift_proxy' {

  # TODO this should not be recommended
  class { 'role_swift_ringbuilder': }

  class { 'role_swift_proxy':
    require => Class['role_swift_ringbuilder'],
  }

}

node 'swift_ringbuilding' {

  include role_swift_ringbuilder

}

#
# classes that are used for role assignment
#
class role_swift {

  class { 'ssh::server::install': }

  class { 'swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => $swift_shared_secret,
    package_ensure => latest,
  }

}

class role_swift_ringbuilder inherits role_swift {

  # collect all of the resources that are needed
  # to rebalance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  class { 'swift::ringbuilder':
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

  class { 'swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }

  @@swift::ringsync { ['account', 'object', 'container']:
    ring_server => $swift_local_net_ip
  }

}

class role_swift_proxy inherits role_swift {

  # curl is only required so that I can run tests
  package { 'curl': ensure => present }

  class { 'memcached':
    listen_ip => '127.0.0.1',
  }

  # TODO should I enable swath in the default config?
  class { 'swift::proxy':
    proxy_local_net_ip => $swift_local_net_ip,
    account_autocreate => true,
    require            => Class['swift::ringbuilder'],
  }
}

class role_swift_storage inherits role_swift {

  # create xfs partitions on a loopback device and mount them
  swift::storage::loopback { '1':
    base_dir     => '/srv/loopback-device',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
  }


  # TODO I need to wrap these in a define so that
  # mcollective can collect that define

  # these exported resources write ring config
  # resources into the database so that they can be
  # consumed by the ringbuilder role
  @@ring_object_device { "${swift_local_net_ip}:6000":
    zone        => $swift_zone,
    device_name => 1,
    weight      => 1,
  }

  @@ring_container_device { "${swift_local_net_ip}:6001":
    zone        => $swift_zone,
    device_name => 1,
    weight      => 1,
  }

  # TODO should device be changed to volume
  @@ring_account_device { "${swift_local_net_ip}:6002":
    zone        => $swift_zone,
    device_name => 1,
    weight      => 1,
  }

  Swift::Ringsync<<||>>

}
