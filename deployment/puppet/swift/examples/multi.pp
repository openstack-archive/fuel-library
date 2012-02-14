#
# Example file for building out a multi-node environment
#

# for this to work, you need to run the nodes in this order:

#
# 1. storage nodes
# 2. ringbuilder
# 3. run the storage nodes again
# 4. run the proxy
# 5. test that everything works!!
#
#
# This example file is almost the
# same as what I have been using
# to build swift in my environment (which is based on vagrant)



$swift_shared_secret='changeme'
$swift_local_net_ip = $ipaddress_eth1

Exec { logoutput => true }

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


  include role_swift_proxy
}

node 'swift_proxy' {

  include role_swift_ringbuilder

}

node 'swift_ringbuilding' {


}

class role_swift {

  class { 'ssh::server::install': }

  class { 'swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => $swift_shared_secret,
    package_ensure => latest,
  }

}

class role_swift_ringbuilder inherits role_swift {

  # collect all resource that we need to rebalance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  class { 'swift::ringbuilder':
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

}

class role_swift_proxy inherits role_swift {

  package { 'curl': ensure => present }

  class { 'memcached':
    listen_ip => $proxy_local_net_ip,
  }

  class { 'swift::ringbuilder':
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }
  # TODO should I enable swath in the default config?
  class { 'swift::proxy':
    account_autocreate => true,
    require            => Class['swift::ringbuilder'],
  }
}

class role_swift_storage inherits role_swift {

  class { 'swift::storage':
    storage_local_net_ip => $swift_local_net_ip,
    devices              => '/srv/node',
  }

  # create xfs partitions on a loopback device and mount them
  swift::storage::loopback { '1':
    base_dir     => '/srv/loopback-device',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }

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

  @@ring_account_device { "${swift_local_net_ip}:6002":
    zone        => $swift_zone,
    device_name => 1,
    weight      => 1,
  }
}
