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


#$swift_admin_password = 'admin_password'
$swift_admin_password = hiera('admin_password', 'admin_password')

# swift specific configurations
#$swift_shared_secret = 'changeme'
$swift_shared_secret = hiera('swift_shared_secret', 'changeme')


#$swift_local_net_ip   = $ipaddress_eth0
$swift_local_net_ip = hiera('swift_local_net_ip', $ipaddress_eth0)

#$swift_keystone_node = '172.16.0.21'
$swift_keystone_node    = hiera('swift_keystone_node', '172.16.0.25')
#$swift_proxy_node    = '172.168.0.25'
$swift_proxy_node       = hiera('swift_proxy_node', '172.16.0.21')

$swift_zone = hiera('swift_zone', 1)
# configurations that need to be applied to all swift nodes

$swift_keystone_db_password    = hiera('keystone_db_password', 'keystone_db_password')
$keystone_admin_token          = hiera('admin_token', 'service_token')
$swift_keystone_admin_email    = hiera('admin_email', 'keystone@localhost')
$swift_keystone_admin_password = hiera('admin_password', 'ChangeMe')

$swift_verbose                 = hiera('verbose', 'True')


# This node can be used to deploy a keystone service.
# This service only contains the credentials for authenticating
# swift
node 'swift-keystone' {

  # set up mysql server
  class { '::mysql::server':
    config_hash => {
      # the priv grant fails on precise if I set a root password
      # TODO I should make sure that this works
      # 'root_password' => $mysql_root_password,
      'bind_address' => '0.0.0.0',
    },
  }

  keystone_config {
    'DEFAULT/log_config': ensure => absent,
  }

  # set up all openstack databases, users, grants
  class { '::keystone::db::mysql':
    password => $swift_keystone_db_password,
  }

  class { '::keystone':
    verbose        => $verbose,
    debug          => $verbose,
    catalog_type   => 'sql',
    admin_token    => $admin_token,
    enabled        => $enabled,
    sql_connection => "mysql://keystone_admin:${swift_keystone_db_password}@127.0.0.1/keystone",
  }

  # Setup the Keystone Identity Endpoint
  class { '::keystone::endpoint': }

  # set up keystone admin users
  class { '::keystone::roles::admin':
    email    => $swift_keystone_admin_email,
    password => $swift_keystone_admin_password,
  }
  # configure the keystone service user and endpoint
  class { '::swift::keystone::auth':
    password       => $swift_admin_password,
    public_address => $swift_proxy_node,
  }

}

#
# The example below is used to model swift storage nodes that
# manage 2 endpoints.
#
# The endpoints are actually just loopback devices. For real deployments
# they would need to be replaced with something that create and mounts xfs
# partitions
#
node /swift-storage/ {

  class { '::swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => $swift_shared_secret,
    package_ensure    => latest,
  }

  # create xfs partitions on a loopback device and mount them
  swift::storage::loopback { ['1', '2']:
    base_dir     => '/srv/loopback-device',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }

  # install all swift storage servers together
  class { '::swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
  }

  # specify endpoints per device to be added to the ring specification
  @@ring_object_device { "${swift_local_net_ip}:6000/1":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_object_device { "${swift_local_net_ip}:6000/2":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_container_device { "${swift_local_net_ip}:6001/1":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_container_device { "${swift_local_net_ip}:6001/2":
    zone   => $swift_zone,
    weight => 1,
  }
  # TODO should device be changed to volume
  @@ring_account_device { "${swift_local_net_ip}:6002/1":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_account_device { "${swift_local_net_ip}:6002/2":
    zone   => $swift_zone,
    weight => 1,
  }

  # collect resources for synchronizing the ring databases
  Swift::Ringsync<<||>>

}


node /swift-proxy/ {

  class { '::swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => $swift_shared_secret,
    package_ensure    => latest,
  }

  # curl is only required so that I can run tests
  package { 'curl': ensure => present }

  class { '::memcached':
    listen_ip => '127.0.0.1',
  }

  # specify swift proxy and all of its middlewares
  class { '::swift::proxy':
    proxy_local_net_ip => $swift_local_net_ip,
    pipeline           => [
      'bulk',
      'catch_errors',
      'healthcheck',
      'cache',
      'ratelimit',
      'swift3',
      's3token',
      'authtoken',
      'keystone',
      'account_quotas',
      'container_quotas',
      'proxy-server'],
    account_autocreate => true,
    # TODO where is the  ringbuilder class?
    require            => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class { [
    '::swift::proxy::account_quotas',
    '::swift::proxy::catch_errors',
    '::swift::proxy::container_quotas',
    '::swift::proxy::healthcheck',
    '::swift::proxy::cache',
    '::swift::proxy::swift3',
  ]: }
  class { '::swift::proxy::bulk':
    max_containers_per_extraction => 10000,
    max_failed_extractions        => 1000,
    max_deletes_per_request       => 10000,
    yield_frequency               => 60,
  }
  class { '::swift::proxy::ratelimit':
    clock_accuracy         => 1000,
    max_sleep_time_seconds => 60,
    log_sleep_time_seconds => 0,
    rate_buffer_seconds    => 5,
    account_ratelimit      => 0,
  }
  class { '::swift::proxy::s3token':
    # assume that the controller host is the swift api server
    auth_host => $swift_keystone_node,
    auth_port => '35357',
  }
  class { '::swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }
  class { '::swift::proxy::authtoken':
    admin_user        => 'swift',
    admin_tenant_name => 'services',
    admin_password    => $swift_admin_password,
    # assume that the controller host is the swift api server
    auth_host         => $swift_keystone_node,
  }

  # collect all of the resources that are needed
  # to balance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  # create the ring
  class { '::swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

  # sets up an rsync db that can be used to sync the ring DB
  class { '::swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
    ring_server => $swift_local_net_ip,
  }

  # deploy a script that can be used for testing
  class { '::swift::test_file':
    auth_server => $swift_keystone_node,
    password    => $swift_keystone_admin_password,
  }
}
