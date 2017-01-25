class openstack_tasks::murano::murano {

  notice('MODULAR: murano/murano.pp')

  prepare_network_config(hiera_hash('network_scheme', {}))

  $murano_hash                = hiera_hash('murano', {})
  $murano_settings_hash       = hiera_hash('murano_settings', {})
  $rabbit_hash                = hiera_hash('rabbit', {})
  $ceilometer_hash            = hiera_hash('ceilometer', {})
  $neutron_config             = hiera_hash('neutron_config', {})
  $public_ip                  = hiera('public_vip')
  $database_ip                = hiera('database_vip')
  $management_ip              = hiera('management_vip')
  $region                     = hiera('region', 'RegionOne')
  $service_endpoint           = hiera('service_endpoint')
  $syslog_log_facility_murano = hiera('syslog_log_facility_murano')
  $debug                      = pick($murano_hash['debug'], hiera('debug', false))
  $default_log_levels         = hiera_hash('default_log_levels')
  $use_syslog                 = hiera('use_syslog', true)
  $use_stderr                 = hiera('use_stderr', false)
  $rabbit_ha_queues           = hiera('rabbit_ha_queues')
  $amqp_port                  = hiera('amqp_port')
  $amqp_hosts                 = hiera('amqp_hosts')
  $external_dns               = hiera_hash('external_dns', {})
  $public_ssl_hash            = hiera_hash('public_ssl', {})
  $ssl_hash                   = hiera_hash('use_ssl', {})
  $primary_controller         = hiera('primary_controller')
  $kombu_compression          = hiera('kombu_compression', $::os_service_default)
  $memcached_servers          = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')

  $public_auth_protocol       = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
  $public_auth_address        = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_ip])

  $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_ip])

  $admin_auth_protocol        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_address         = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_ip])

  $api_bind_host              = get_network_role_property('murano/api', 'ipaddr')

  $murano_plugins             = pick($murano_hash['plugins'], {})

  #################################################################

  if $murano_hash['enabled'] {

    $firewall_rule  = '202 murano-api'

    $api_bind_port  = '8082'

    $murano_user    = pick($murano_hash['user'], 'murano')
    $tenant         = pick($murano_hash['tenant'], 'services')

    $db_type        = pick($murano_hash['db_type'], 'mysql+pymysql')
    $db_user        = pick($murano_hash['db_user'], 'murano')
    $db_name        = pick($murano_hash['db_name'], 'murano')
    $db_password    = pick($murano_hash['db_password'])
    $db_host        = pick($murano_hash['db_host'], $database_ip)
    # LP#1526938 - python-mysqldb supports this, python-pymysql does not
    if $::os_package_type == 'debian' {
      $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
    } else {
      $extra_params = { 'charset' => 'utf8' }
    }
    $db_connection = os_database_connection({
      'dialect'  => $db_type,
      'host'     => $db_host,
      'database' => $db_name,
      'username' => $db_user,
      'password' => $db_password,
      'extra'    => $extra_params
    })

    $transport_url = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')

    $external_network = get_ext_net_name($neutron_config['predefined_networks'])

    $repository_url = has_key($murano_settings_hash, 'murano_repo_url') ? {
      true    => $murano_settings_hash['murano_repo_url'],
      default => 'http://storage.apps.openstack.org',
    }

    ####### Disable upstart startup on install #######
    tweaks::ubuntu_service_override { ['murano-api', 'murano-engine']:
      package_name => 'murano',
    }

    firewall { $firewall_rule :
      dport  => $api_bind_port,
      proto  => 'tcp',
      action => 'accept',
    }


    # NOTE(aschultz): UCA does not have the glance artifacts plugin package
    # we can remove the os_package_type once UCA provides the package
    # TODO(aschultz): switch to dig at some point
    if $murano_plugins and $murano_plugins['glance_artifacts_plugin'] and $murano_plugins['glance_artifacts_plugin']['enabled'] and ($::os_package_type == 'debian') {
      $packages_service = 'glare'
      $enable_glare     = true

      package {'murano-glance-artifacts-plugin':
        ensure  => present,
      }

      include ::glance::params
      ensure_resource('service', 'glance-glare',
        { ensure => running, name => $::glance::params::glare_service_name })
      Package['murano-glance-artifacts-plugin'] ~> Service['glance-glare']
    } else {
      $packages_service = 'murano'
      $enable_glare     = false
    }

    # TODO(mmalchuk) remove this after LP#1628580 merged
    Exec<| title == 'murano-dbmanage' |> {
      tries => '10',
      try_sleep => '5'
    }

    class { '::murano' :
      debug                  => $debug,
      use_syslog             => $use_syslog,
      use_stderr             => $use_stderr,
      log_facility           => $syslog_log_facility_murano,
      database_connection    => $db_connection,
      default_transport_url  => $transport_url,
      sync_db                => $primary_controller,
      auth_uri               => "${public_auth_protocol}://${public_auth_address}:5000/",
      admin_user             => $murano_user,
      admin_password         => $murano_hash['user_password'],
      admin_tenant_name      => $tenant,
      identity_uri           => "${admin_auth_protocol}://${admin_auth_address}:35357/",
      notification_driver    => $ceilometer_hash['notification_driver'],
      use_neutron            => true,
      packages_service       => $packages_service,
      rabbit_ha_queues       => $rabbit_ha_queues,
      rabbit_own_host        => $public_ip,
      rabbit_own_port        => $murano_hash['rabbit']['port'],
      rabbit_own_vhost       => $murano_hash['rabbit']['vhost'],
      rabbit_own_user        => pick($murano_hash['rabbit']['user'], 'murano'),
      rabbit_own_password    => $murano_hash['rabbit_password'],
      default_router         => 'murano-default-router',
      default_nameservers    => pick($external_dns['dns_list'], '8.8.8.8'),
      service_host           => $api_bind_host,
      service_port           => $api_bind_port,
      external_network       => $external_network,
      use_trusts             => true,
      kombu_compression      => $kombu_compression,
      memcached_servers      => $local_memcached_server,
    }

    class { '::murano::api':
      host    => $api_bind_host,
      port    => $api_bind_port,
    }

    class { '::murano::engine': }

    class { '::murano::client': }

    class { '::murano::dashboard':
      enable_glare => $enable_glare,
      repo_url     => $repository_url,
      sync_db      => false,
    }

    Firewall[$firewall_rule] -> Class['::murano::api']
  }
}
