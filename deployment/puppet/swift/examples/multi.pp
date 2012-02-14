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

if($clientcert == 'swift_storage_1') {

  $swift_zone = 1
  include role_swift_storage

} elsif($clientcert == 'swift_storage_2') {

  $swift_zone = 2
  include role_swift_storage

} elsif($clientcert == 'swift_storage_3') {

  $swift_zone = 3
  include role_swift_storage

} elsif($clientcert == 'swift_proxy') {

  include role_swift_proxy

} elsif($clientcert == 'swift_ringbuilding') {

  include role_swift_ringbuilder

} #elsif($clientcert == 'puppetmaster') {

class role_puppetmaster {

  class { 'mysql::server':
    config_hash => {'bind_address' => '127.0.0.1'}
  }
  class { 'mysql::ruby': }
  package { 'activerecord':
    ensure   => '2.3.5',
    provider => 'gem',
  }

  class { 'puppet::master':
    modulepath              => '/vagrant/modules',
    manifest                => '/vagrant/manifests/site.pp',
    storeconfigs            => true,
    storeconfigs_dbuser     => 'dan',
    storeconfigs_dbpassword => 'foo',
    storeconfigs_dbadapter  => 'mysql',
    storeconfigs_dbserver   => 'localhost',
    storeconfigs_dbsocket   => '/var/run/mysqld/mysqld.sock',
    version                 => installed,
    puppet_master_package   => 'puppet',
    autosign                => 'true',
    certname                => $clientcert,
  }
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

  class { 'swift::storage':
    storage_local_net_ip => $swift_local_net_ip,
  }

  # create xfs partitions on a loopback device and mount them
  swift::storage::loopback { '1':
    base_dir     => '/srv/loopback-device',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }

  Swift::Storage::Device {
    storage_local_net_ip => $swift_local_net_ip,
    devices              => '/srv/node',
  }

  swift::storage::device { '8001': type => 'object',}
  @@ring_object_device { "${swift_local_net_ip}:8001":
    zone        => 1,
    device_name => 1,
    weight      => 1,
  }

  swift::storage::device { '8002': type => 'container',}
  @@ring_container_device { "${swift_local_net_ip}:8002":
    zone        => 1,
    device_name => 1,
    weight      => 1,
  }

  swift::storage::device { '8003': type => 'account',}
  @@ring_account_device { "${swift_local_net_ip}:8003":
    zone        => 1,
    device_name => 1,
    weight      => 1,
  }


}
