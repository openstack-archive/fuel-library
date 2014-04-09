
# params needed by both the compute and controller
$rabbit_password    = 'rabbit_pw'
$rabbit_user        = 'nova'
$nova_db_password   = 'nova_pass'
$nova_user_password = 'nova_pass'

#
# indicates that all nova config entries that we did
# not specifify in Puppet should be purged from file
#
resources { 'nova_config':
  purge => true,
}

Exec {
  logoutput => true,
}

# this is a hack that I have to do b/c openstack nova
# sets up a route to reroute calls to the metadata server
# to its own server which fails
file { '/usr/lib/ruby/1.8/facter/ec2.rb':
  ensure => absent,
}

node /controller/ {

  # hostname that works internally in ec2
  $controller_host = $hostname

  $glance_api_servers = "${controller_host}:9292"

  $mysql_root_password  = 'sql_pass'
  $keystone_db_password = 'keystone_pass'
  $keystone_admin_token = 'keystone_admin_token'

  $admin_email         = 'dan@puppetlabs.com'
  $admin_user_password = 'ChangeMe'

  $glance_db_password   = 'glance_pass'
  $glance_user_password = 'glance_pass'

  $nova_db = "mysql://nova:${nova_db_password}@${controller_host}/nova"

  # export all of the things that will be needed by the clients
  @@nova_config { 'rabbit_hosts': value => $controller_host }
  Nova_config <| title == 'rabbit_hosts' |>
  @@nova_config { 'database_connection': value => $nova_db }
  Nova_config <| title == 'database_connection' |>
  @@nova_config { 'glance_api_servers': value => $glance_api_servers }
  Nova_config <| title == 'glance_api_servers' |>

  # set up mysql server
  class { 'mysql::server':
    config_hash => {
      # the priv grant fails on precise if I set a root password
      # 'root_password' => $mysql_root_password,
      'bind_address'  => '0.0.0.0'
    }
  }

  ####### KEYSTONE ###########

  # set up keystone database
  class { 'keystone::db::mysql':
    password => $keystone_db_password,
  }
  # set up the keystone config for mysql
  class { 'keystone::config::mysql':
    password => $keystone_db_password,
  }
  # set up keystone
  class { 'keystone':
    admin_token  => $keystone_admin_token,
    bind_host    => '127.0.0.1',
    verbose      => true,
    debug        => true,
    catalog_type => 'sql',
  }
  # set up keystone admin users
  class { 'keystone::roles::admin':
    email    => $admin_email,
    password => $admin_user_password,
  }
  # set up the keystone service and endpoint
  class { 'keystone::endpoint': }

  ######## END KEYSTONE ##########

  ######## BEGIN GLANCE ##########

  class { 'glance::keystone::auth':
    password => $glance_user_password,
  }

  class { 'glance::db::mysql':
    host     => '127.0.0.1',
    password => $glance_db_password,
  }

  class { 'glance::api':
    verbose           => true,
    debug             => true,
    auth_type         => 'keystone',
    auth_host         => '127.0.0.1',
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
  }
  class { 'glance::backend::file': }

  class { 'glance::registry':
    verbose             => true,
    debug               => true,
    auth_type           => 'keystone',
    auth_host           => '127.0.0.1',
    auth_port           => '35357',
    keystone_tenant     => 'services',
    keystone_user       => 'glance',
    keystone_password   => $glance_user_password,
    database_connection => "mysql://glance:${glance_db_password}@127.0.0.1/glance",
  }


  ######## END GLANCE ###########

  ######## BEGIN NOVA ###########

  class { 'nova::keystone::auth':
    password => $nova_user_password,
  }

  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
  }

  class { 'nova::db::mysql':
    password      => $nova_db_password,
    host          => 'localhost',
    allowed_hosts => ['%', $controller_host],
  }

  class { 'nova':
    database_connection => false,
    # this is false b/c we are exporting
    rabbit_hosts        => false,
    rabbit_userid       => $rabbit_user,
    rabbit_password     => $rabbit_password,
    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => false,
    network_manager     => 'nova.network.manager.FlatDHCPManager',
  }

  class { 'nova::api':
    enabled        => true,
    admin_password => $nova_user_password,
  }

  class { 'nova::scheduler':
    enabled => true,
  }

  class { 'nova::network':
    enabled => true,
  }

  nova::manage::network { 'nova-vm-net':
    network       => '11.0.0.0/24',
    available_ips => 128,
  }

  nova::manage::floating { 'nova-vm-floating':
    network => '10.128.0.0/24',
  }

  class { 'nova::objectstore':
    enabled => true
  }

  ######## Horizon ########

  class { 'memcached':
    listen_ip => '127.0.0.1',
  }

  class { 'horizon': }


  ######## End Horizon #####

  ######## Credentails and tests ###

  # lay down a file with credentials stored in it
  file { '/root/auth':
    content =>
  '
  export OS_TENANT_NAME=openstack
  export OS_USERNAME=admin
  export OS_PASSWORD=ChangeMe
  export OS_AUTH_URL="http://localhost:5000/v2.0/"
  '
  }
}

####### tests ###

node /compute/ {

  class { 'nova':
    # set db and rabbit to false so that the resources will be collected
    database_connection => false,
    rabbit_hosts        => false,
    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => false,
    rabbit_userid       => $rabbit_user,
    rabbit_password     => $rabbit_password,
    network_manager     => 'nova.network.manager.FlatDHCPManager',
    admin_password      => $nova_user_password,
  }

  class { 'nova::compute':
    enabled => true,
  }

  class { 'nova::compute::libvirt':
    libvirt_type                => 'qemu',
    flat_network_bridge_ip      => '11.0.0.1',
    flat_network_bridge_netmask => '255.255.255.0',
  }
}
