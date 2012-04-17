$rabbit_password = 'rabbit_pw'
$rabbit_user = 'nova'

$glance_api_servers = '127.0.0.1:9292'

$mysql_root_password  = 'sql_pass'
$keystone_db_password = 'keystone_pass'
$keystone_admin_token = 'keystone_admin_token'

$admin_email         = 'dan@puppetlabs.com'
$admin_user_password = 'ChangeMe'

$nova_db_password   = 'nova_pass'
$nova_user_password = 'nova_pass'

$glance_db_password   = 'glance_pass'
$glance_user_password = 'glance_pass'

#
# indicates that all nova config entries that we did
# not specifify in Puppet should be purged from file
#
resources { 'nova_config':
  purge => true,
}

#if $::osfamily == 'Debian' {
#  # temporarily update this to use the
#  # latest tested packages from precise
#  # eventually, these packages need to be moved
#  # to the openstack module
#  stage { 'nova_ppa':
#    before => Stage['main']
#  }
#
#  class { 'apt':
#    stage => 'nova_ppa',
#  }
#  class { 'keystone::repo::trunk':
#    stage => 'nova_ppa',
#  }
#}

# this is a hack that I have to do b/c openstack nova
# sets up a route to reroute calls to the metadata server
# to its own server which fails
file { '/usr/lib/ruby/1.8/facter/ec2.rb':
  ensure => absent,
}

# set up mysql server
class { 'mysql::server':
  config_hash => {
    # the priv grant fails on precise if I set a root password
    # 'root_password' => $mysql_root_password,
    'bind_address'  => '127.0.0.1'
  }
}

####### KEYSTONE ###########

# set up keystone database
class { 'keystone::mysql':
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
  log_verbose  => true,
  log_debug    => true,
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

class { 'glance::db':
  host     => '127.0.0.1',
  password => $glance_db_password,
}

class { 'glance::api':
  log_verbose       => 'True',
  log_debug         => 'True',
  auth_type         => 'keystone',
  auth_host         => '127.0.0.1',
  auth_port         => '35357',
  keystone_tenant   => 'services',
  keystone_user     => 'glance',
  keystone_password => $glance_user_password,
}
class { 'glance::backend::file': }

class { 'glance::registry':
  log_verbose       => 'True',
  log_debug         => 'True',
  auth_type         => 'keystone',
  auth_host         => '127.0.0.1',
  auth_port         => '35357',
  keystone_tenant   => 'services',
  keystone_user     => 'glance',
  keystone_password => $glance_user_password,
  sql_connection    => "mysql://glance:${glance_db_password}@127.0.0.1/glance",
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

class { 'nova::db':
  password => $nova_db_password,
  host     => 'localhost',
}

class { 'nova':
  sql_connection     => "mysql://nova:${nova_db_password}@localhost/nova",
  rabbit_userid      => $rabbit_user,
  rabbit_password    => $rabbit_password,
  image_service      => 'nova.image.glance.GlanceImageService',
  glance_api_servers => '127.0.0.1:9292',
  network_manager    => 'nova.network.manager.FlatDHCPManager',
  admin_password     => $nova_user_password,
}

class { 'nova::api':
  enabled => true
}

class { 'nova::scheduler':
  enabled => true
}

class { 'nova::network':
  enabled => true
}

nova::manage::network { "nova-vm-net":
  network       => '11.0.0.0/24',
  available_ips => 128,
}

nova::manage::floating { "nova-vm-floating":
  network       => '10.128.0.0/24',
}

class { 'nova::objectstore':
  enabled => true
}

class { 'nova::volume':
  enabled => true
}

class { 'nova::cert':
  enabled => true
}

class { 'nova::compute':
  enabled => true,
}

class { 'nova::compute::libvirt':
  libvirt_type => 'qemu',
}

nova::network::bridge { 'br100':
  ip      => '11.0.0.1',
  netmask => '255.255.255.0',
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

####### tests ###
