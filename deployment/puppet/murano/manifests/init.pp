class murano (
  # package
  $murano_package_name                   = 'murano',
  # keystone
  $murano_keystone_host                  = '127.0.0.1',
  $murano_keystone_port                  = '5000',
  $murano_keystone_protocol              = 'http',
  $murano_keystone_tenant                = 'services',
  $murano_keystone_user                  = 'murano',
  $murano_keystone_password              = 'swordfish',
  $murano_keystone_signing_dir           = '/tmp/keystone-signing-muranoapi',
  # murano
  $use_syslog                            = false,
  $debug                                 = false,
  $verbose                               = false,
  $syslog_log_facility                   = 'LOG_LOCAL0',
  $murano_log_dir                        = '/var/log/murano',
  $murano_log_file                       = '/var/log/murano/murano.log',
  $murano_data_dir                       = '/var/cache/murano',
  $murano_api_host                       = '127.0.0.1',
  # rabbit configuration
  # NOTE:
  #  Murano uses separate rabbitmq server for communication with agents.
  #   This server is launched on each controller node and uses port 55572.
  #  Separate rabbitmq is used to address security concern that instances
  #   managed by Murano have access to the 'system' RabbitMQ and thus could
  #   have access to OpenStack internal data.
  # murano_rabbit_ha_hosts is used by murano-api and works with oslo.messaging
  $murano_rabbit_ha_hosts                = '127.0.0.1:5672',
  $murano_rabbit_ha_queues               = false,
  # murano_rabbit_host and murano_rabbit_port are used by murano-engine,
  #   which communicates with rabbitmq directly.
  $murano_rabbit_host                    = '127.0.0.1',
  $murano_rabbit_port                    = '55572',
  $murano_rabbit_ssl                     = false,
  $murano_rabbit_ca_certs                = '',
  $murano_os_rabbit_userid               = 'guest',
  $murano_os_rabbit_passwd               = 'guest',
  $murano_own_rabbit_userid              = 'murano',
  $murano_own_rabbit_passwd              = 'murano',
  $murano_rabbit_virtual_host            = '/',
  # murano-api.conf
  $murano_bind_host                      = '0.0.0.0',
  $murano_bind_port                      = '8082',
  $murano_log_file                       = '/var/log/murano/murano-api.log',
  #$murano_database_auto_create           = true,
  # mysql
  $murano_db_password                    = 'murano',
  $murano_db_name                        = 'murano',
  $murano_db_user                        = 'murano',
  $murano_db_host                        = 'localhost',
  $murano_db_allowed_hosts               = ['localhost','%'],
  # neutron
  $use_neutron                           = false,
  # Other parameters
  $primary_controller                    = true,
  # Controller addresses
  $admin_address                         = '127.0.0.1',
  $public_address                        = '127.0.0.1',
  $internal_address                      = '127.0.0.1',
) {

  Class['mysql::server'] -> Class['murano::db::mysql'] -> Class['murano::murano_rabbitmq'] -> Class['murano::keystone'] -> Class['murano::python_muranoclient'] -> Class['murano::api'] -> Class['murano::apps'] -> Class['murano::dashboard'] -> Class['murano::cirros']

  User['murano'] -> Class['murano::api'] -> File <| title == $murano_log_dir |>

  $murano_keystone_auth_url = "${murano_keystone_protocol}://${murano_keystone_host}:${murano_keystone_port}/v2.0"

  group { 'murano':
    ensure => present,
    system => true,
  }

  $murano_user_shell = $::osfamily ? {
    'RedHat' => '/sbin/nologin',
    'Debian' => '/usr/sbin/nologin',
    default  => '/sbin/nologin',
  }

  user { 'murano':
    ensure  => present,
    comment => 'Murano User',
    gid     => 'murano',
    system  => true,
    shell   => $murano_user_shell,
    require => Group['murano'],
  }

  file { $murano_data_dir:
    ensure => directory,
    owner  => 'murano',
    group  => 'murano',
    mode   => '0755',
  }

  file { $murano_log_dir:
    ensure => directory,
    owner  => 'murano',
    group  => 'murano',
    mode   => '0750',
  }

  class { 'murano::db::mysql':
    password                             => $murano_db_password,
    dbname                               => $murano_db_name,
    user                                 => $murano_db_user,
    dbhost                               => $murano_db_host,
    allowed_hosts                        => $murano_db_allowed_hosts,
  }

  class { 'murano::python_muranoclient':
  }

  class { 'murano::api' :
    use_syslog                           => $use_syslog,
    debug                                => $debug,
    verbose                              => $verbose,
    log_file                             => "${murano_log_dir}/murano.log",
    syslog_log_facility                  => $syslog_log_facility,

    auth_host                            => $murano_keystone_host,
    auth_port                            => $murano_keystone_port,
    auth_protocol                        => $murano_keystone_protocol,
    admin_tenant_name                    => $murano_keystone_tenant,
    admin_user                           => $murano_keystone_user,
    admin_password                       => $murano_keystone_password,
    signing_dir                          => $murano_keystone_signing_dir,

    bind_host                            => $murano_bind_host,
    bind_port                            => $murano_bind_port,

    api_host                             => $murano_api_host,

    rabbit_host                          => $murano_rabbit_host,
    rabbit_port                          => $murano_rabbit_port,
    rabbit_ha_hosts                      => $murano_rabbit_ha_hosts,
    rabbit_ha_queues                     => $murano_rabbit_ha_queues,
    rabbit_use_ssl                       => $murano_rabbit_ssl,
    rabbit_ca_certs                      => $murano_rabbit_ca_certs,
    os_rabbit_userid                     => $murano_os_rabbit_userid,
    os_rabbit_password                   => $murano_os_rabbit_passwd,
    murano_rabbit_userid                 => $murano_own_rabbit_userid,
    murano_rabbit_password               => $murano_own_rabbit_passwd,
    rabbit_virtual_host                  => $murano_rabbit_virtual_host,

    murano_db_password                   => $murano_db_password,
    murano_db_name                       => $murano_db_name,
    murano_db_user                       => $murano_db_user,
    murano_db_host                       => $murano_db_host,

    primary_controller                   => $primary_controller,

    use_neutron                          => $use_neutron,
    default_router                       => 'murano-default-router',
    default_network                      => 'net04_ext',
  }

  class { 'murano::apps':
    primary_controller => $primary_controller,
  }

  class { 'murano::dashboard' :
    settings_py       => '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
  }

  class { 'murano::murano_rabbitmq' :
    rabbit_user        => $murano_own_rabbit_userid,
    rabbit_password    => $murano_own_rabbit_passwd,
    rabbit_vhost       => $murano_rabbit_virtual_host,
    rabbitmq_main_port => $murano_rabbit_port,
  }

  class { 'murano::cirros':
  }

  class { 'murano::keystone':
    tenant           => $murano_keystone_tenant,
    user             => $murano_keystone_user,
    password         => $murano_keystone_password,
    admin_address    => $admin_address,
    public_address   => $public_address,
    internal_address => $internal_address,
    murano_api_port  => $murano_bind_port,
  }

}
