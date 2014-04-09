$db_host     = 'db'
$db_username = 'nova'
$db_name     = 'nova'
$db_password = 'password'

$rabbit_user     = 'nova'
$rabbit_password = 'nova'
$rabbit_vhost    = '/'
$rabbit_hosts    = ['rabbitmq:5672']
$rabbit_port     = '5672'

$glance_api_servers = 'glance:9292'

$api_server = 'controller'

resources { 'nova_config':
  purge => true,
}

# this is a hack that I have to do b/c openstack nova
# sets up a route to reroute calls to the metadata server
# to its own server which fails
file { '/usr/lib/ruby/1.8/facter/ec2.rb':
  ensure => absent,
}

node db {
  class { 'mysql::server':
    config_hash => {
      'bind_address' => '0.0.0.0'
    }
  }
  class { 'mysql::ruby': }
  class { 'nova::db::mysql':
    password      => $db_password,
    dbname        => $db_name,
    user          => $db_username,
    host          => $clientcert,
    # does glance need access?
    allowed_hosts => ['controller', 'glance', 'compute'],
  }
}

node controller {
  class { 'nova::controller':
    db_password         => $db_password,
    db_name             => $db_name,
    db_user             => $db_username,
    db_host             => $db_host,

    rabbit_password     => $rabbit_password,
    rabbit_userid       => $rabbit_user,
    rabbit_virtual_host => $rabbit_vhost,
    rabbit_hosts        => $rabbit_hosts,

    image_service       => 'nova.image.glance.GlanceImageService',

    glance_api_servers  => $glance_api_servers,

    libvirt_type        => 'qemu',
  }
}

node compute {
  class { 'nova::compute':
    api_server     => $api_server,
    enabled        => true,
    api_port       => 8773,
    aws_address    => '169.254.169.254',
  }
  class { 'nova::compute::libvirt':
    libvirt_type                => 'qemu',
    flat_network_bridge         => 'br100',
    flat_network_bridge_ip      => '11.0.0.1',
    flat_network_bridge_netmask => '255.255.255.0',
  }
  class { 'nova':
    verbose             => $verbose,
    database_connection => "mysql://${db_username}:${db_password}@${db_host}/${db_name}",
    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => $glance_api_servers,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_userid       => $rabbit_user,
    rabbit_password     => $rabbit_password,
    rabbit_virtual_host => $rabbit_virtual_host,
  }
}

node glance {
  # set up glance server
  class { 'glance::api': }

  class { 'glance::registry': }

}

node rabbitmq {
  class { 'nova::rabbitmq':
    userid       => $rabbit_user,
    password     => $rabbit_password,
    port         => $rabbit_port,
    virtual_host => $rabbit_vhost,
  }
}

node puppetmaster {
  class { 'concat::setup': }
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
    package_provider        => 'gem',
    autosign                => true,
    certname                => $clientcert,
  }
}

node all {
  #
  # This manifest installs all of the nova
  # components on one node.

  class { 'mysql::server': }
  class { 'keystone::config::mysql':
    password => 'keystone'
  }
  class { 'keystone':
    verbose      => true,
    debug        => true,
    catalog_type => 'sql',
  }->
  class { 'keystone::mysql':
    password => 'keystone',
  }->
  class { 'keystone::roles::admin': }

  class { 'nova::all':
    db_password         => 'password',
    db_name             => 'nova',
    db_user             => 'nova',
    db_host             => 'localhost',

    rabbit_password     => 'rabbitpassword',
    rabbit_userid       => 'rabbit_user',
    rabbit_virtual_host => '/',
    rabbit_hosts        => ['localhost:5672'],

    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => $glance_api_servers,

    libvirt_type        => 'qemu',
  }
}


node default {
  fail("could not find a matching node entry for ${clientcert}")
}
