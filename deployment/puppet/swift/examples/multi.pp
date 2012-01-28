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

Exec { logoutput => true }

if($clientcert == 'swift_storage_1') {

  $swift_local_net_ip = $ipaddress
  $swift_zone = 1
  include role_swift_storage

} elsif($clientcert == 'swift_storage_2') {

  $swift_local_net_ip = $ipaddress
  $swift_zone = 2
  include role_swift_storage

} elsif($clientcert == 'swift_storage_2') {

  $swift_local_net_ip = $ipaddress
  $swift_zone = 3
  include role_swift_storage

} elsif($clientcert == 'swift_proxy') {

  $swift_local_net_ip = $ipaddress
  include role_swift_proxy

} elsif($clientcert == 'swift_ringbuilding') {

  $swift_local_net_ip = $ipaddress
  include role_swift_ringbuilder

}

class role_swift {

  class { 'ssh::server::install': }

  class { 'swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => $swift_shared_secret,
    package_ensure => latest,
  }

}

class role_swift_ringbuilder inherits role_swif {

  class { 'swift::ringbuilder':
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

  # collect the ring devices to build
  # TODO - this should be done with resource collection
  include ring_hack

  # now build an rsync server to host the data

}

class role_swift_proxy inherits role_swift {

  package { 'curl': ensure => present }

  class { 'memcached':
    listen_ip => $proxy_local_net_ip,
  }

  # TODO should I enable swath in the default config?
  class { 'swift::proxy':
    account_autocreate => true,
    require            => Class['swift::ringbuilder'],
  }
}

class role_swift_storage inherits role_swift {

  class { 'swift::storage': }

  # create xfs partitions on a loopback device and mount them
  swift::storage::loopback { '1':
    require => Class['swift'],
  }

  swift::storage::device::object { '6001':
    device_name => '1',
    zone        => $swift_zone,
    weight      => 1,
    storage_local_net_ip => $swift_local_net_ip,
    manage_ring => false,
  }
  swift::storage::device::container { '6002':
    device_name => '1',
    zone        => $swift_zone,
    weight      => 1,
    storage_local_net_ip => $swift_local_net_ip,
    manage_ring => false,
  }
  swift::storage::device::account { '6003':
    device_name => '1',
    zone        => $swift_zone,
    weight      => 1,
    storage_local_net_ip => $swift_local_net_ip,
    manage_ring => false,
  }
}

class ring_hack {

}
