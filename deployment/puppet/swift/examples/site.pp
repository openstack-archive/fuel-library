Exec { logoutput => true, path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'] }

stage {'openstack-custom-repo': before => Stage['main']}
$mirror_type="default"
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type=>$mirror_type }



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
# 4. run the proxy
# 5. test that everything works!!
# this site manifest serves as an example of how to
# deploy various swift environments

$admin_email          = 'dan@example_company.com'
$keystone_db_password = 'keystone_db_password'
$keystone_admin_token = 'keystone_token'
$admin_user           = 'admin'
$admin_password       = 'admin_password'

$swift_user_password  = 'swift_pass'
# swift specific configurations
$swift_shared_secret  = 'changeme'
$swift_local_net_ip   = $ipaddress_eth0

$swift_proxy_address    = '192.168.1.16'
$controller_node_public = '192.168.122.100' 

$verbose                = true

# This node can be used to deploy a keystone service.
# This service only contains the credentials for authenticating
# swift
node keystone {
  # set up mysql server
  class { 'mysql::server':
    config_hash => {
      # the priv grant fails on precise if I set a root password
      # TODO I should make sure that this works
      # 'root_password' => $mysql_root_password,
      'bind_address'  => '0.0.0.0'
    }
  }
  # set up all openstack databases, users, grants
  class { 'keystone::db::mysql':
    password => $keystone_db_password,
  }

  # in stall and configure the keystone service
  class { 'keystone':
    admin_token  => $keystone_admin_token,
    # we are binding keystone on all interfaces
    # the end user may want to be more restrictive
    bind_host    => '0.0.0.0',
    verbose  => $verbose,
    debug    => $verbose,
    catalog_type => 'sql',
  }

  # set up keystone database
  # set up the keystone config for mysql
  class { 'openstack::db::mysql':
    keystone_db_password => $keystone_db_password,
  }
  # set up keystone admin users
  class { 'keystone::roles::admin':
    email    => $admin_email,
    password => $admin_password,
  }
  # configure the keystone service user and endpoint
  class { 'swift::keystone::auth':
    password => $swift_user_password,
    address  => $swift_proxy_address,
  }
}

# configurations that need to be applied to all swift nodes
node swift_base  {

  class { 'ssh::server::install': }

  class { 'swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => 'swift_shared_secret',
    package_ensure    => installed,
  }
  
  class { 'rsync::server':
    use_xinetd => true,
    address    => $swift_local_net_ip,
    use_chroot => 'no',
  }


}

# The following specifies 3 swift storage nodes
node /fuel-swift-01/ inherits swift_base {

  $swift_zone = 1
  include role_swift_storage

}
node /fuel-swift-02/ inherits swift_base {

  $swift_zone = 2
  include role_swift_storage

}
node /fuel-swift-03/ inherits swift_base {

  $swift_zone = 3
  include role_swift_storage

}

#
# The example below is used to model swift storage nodes that
# manage 2 endpoints.
#
# The endpoints are actually just loopback devices. For real deployments
# they would need to be replaced with something that create and mounts xfs
# partitions
#
class role_swift_storage {

  # create xfs partitions on a loopback device and mount them
  swift::storage::loopback { ['dev1', 'dev2']:
    base_dir     => '/srv/loopback-device',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
    swift_zone           => $swift_zone
  }

  # collect resources for synchronizing the ring databases
  Swift::Ringsync<<| tag == "${::deployment_id}::${::environment}" |>>

}


node /fuel-swiftproxy-01/ inherits swift_base {

  # curl is only required so that I can run tests
  package { 'curl': ensure => present }

  class { 'memcached':
    listen_ip => '127.0.0.1',
  }

  # specify swift proxy and all of its middlewares
  class { 'swift::proxy':
    proxy_local_net_ip => $swift_local_net_ip,
    pipeline           => [
      'catch_errors',
      'healthcheck',
      'cache',
      'ratelimit',
      'swift3',
#      's3token',
      'authtoken',
      'keystone',
      'proxy-server'
    ],
    account_autocreate => true,
    # TODO where is the  ringbuilder class?
    require            => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class { [
    'swift::proxy::catch_errors',
    'swift::proxy::healthcheck',
    'swift::proxy::cache',
    'swift::proxy::swift3',
  ]: }
  class { 'swift::proxy::ratelimit':
    clock_accuracy         => 1000,
    max_sleep_time_seconds => 60,
    log_sleep_time_seconds => 0,
    rate_buffer_seconds    => 5,
    account_ratelimit      => 0
  }
#  class { 'swift::proxy::s3token':
    # assume that the controller host is the swift api server
#    auth_host     => $controller_node_public,
#    auth_port     => '35357',
#  }
  class { 'swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }
  class { 'swift::proxy::authtoken':
    admin_user        => $admin_user,
    admin_tenant_name => 'openstack',
    admin_password    => $admin_password,
    # assume that the controller host is the swift api server
    auth_host         => $controller_node_public,
  }

  # collect all of the resources that are needed
  # to balance the ring
  Ring_object_device <<| tag == "${::deployment_id}::${::environment}" |>>
  Ring_container_device <<| tag == "${::deployment_id}::${::environment}" |>>
  Ring_account_device <<| tag == "${::deployment_id}::${::environment}" |>>

  # create the ring
  class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }
   Class['ringbuilder'] -> Class['swift::ringserver']
  # sets up an rsync db that can be used to sync the ring DB
  class { 'swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
   ring_server => $swift_local_net_ip
 }

  # deploy a script that can be used for testing
  file { '/tmp/swift_keystone_test.rb':
    source => 'puppet:///modules/swift/swift_keystone_test.rb'
  }
}

