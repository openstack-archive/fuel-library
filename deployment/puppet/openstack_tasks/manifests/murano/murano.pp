class openstack_tasks::murano::murano {

  notice('MODULAR: murano/murano.pp')

  prepare_network_config(hiera_hash('network_scheme', {}))

  $murano_hash                = hiera_hash('murano', {})
  $murano_settings_hash       = hiera_hash('murano_settings', {})
  $rabbit_hash                = hiera_hash('rabbit', {})
  $neutron_config             = hiera_hash('neutron_config', {})
  $public_ip                  = hiera('public_vip')
  $database_ip                = hiera('database_vip')
  $management_ip              = hiera('management_vip')
  $region                     = hiera('region', 'RegionOne')
  $use_neutron                = hiera('use_neutron', false)
  $service_endpoint           = hiera('service_endpoint')
  $syslog_log_facility_murano = hiera('syslog_log_facility_murano')
  $debug                      = pick($murano_hash['debug'], hiera('debug', false))
  $verbose                    = pick($murano_hash['verbose'], hiera('verbose', true))
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
  $kombu_compression          = hiera('kombu_compression', '')

  $public_auth_protocol       = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
  $public_auth_address        = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_ip])

  $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])

  $admin_auth_protocol        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_address         = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])

  $api_bind_host              = get_network_role_property('murano/api', 'ipaddr')

  $external_lb                = hiera('external_lb', false)

  $murano_plugins             = pick($murano_hash['plugins'], {})

  #################################################################

  if $murano_hash['enabled'] {

    $firewall_rule  = '202 murano-api'

    $api_bind_port  = '8082'

    $murano_user    = pick($murano_hash['user'], 'murano')
    $tenant         = pick($murano_hash['tenant'], 'services')

    $db_type        = 'mysql'
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

    $external_network = $use_neutron ? {
      true    => get_ext_net_name($neutron_config['predefined_networks']),
      default => undef,
    }

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

    if $murano_plugins and $murano_plugins['glance_artifacts_plugin'] and $murano_plugins['glance_artifacts_plugin']['enabled'] {
      $packages_service = 'glance'
      $enable_glare     = true
    } else {
      $packages_service = 'murano'
      $enable_glare     = false
    }

    class { '::murano' :
      verbose             => $verbose,
      debug               => $debug,
      use_syslog          => $use_syslog,
      use_stderr          => $use_stderr,
      log_facility        => $syslog_log_facility_murano,
      database_connection => $db_connection,
      sync_db             => $primary_controller,
      auth_uri            => "${public_auth_protocol}://${public_auth_address}:5000/",
      admin_user          => $murano_user,
      admin_password      => $murano_hash['user_password'],
      admin_tenant_name   => $tenant,
      identity_uri        => "${admin_auth_protocol}://${admin_auth_address}:35357/",
      notification_driver => 'messagingv2',
      use_neutron         => $use_neutron,
      packages_service    => $packages_service,
      rabbit_os_user      => $rabbit_hash['user'],
      rabbit_os_password  => $rabbit_hash['password'],
      rabbit_os_port      => $amqp_port,
      rabbit_os_host      => split($amqp_hosts, ','),
      rabbit_ha_queues    => $rabbit_ha_queues,
      rabbit_own_host     => $public_ip,
      rabbit_own_port     => $murano_hash['rabbit']['port'],
      rabbit_own_vhost    => $murano_hash['rabbit']['vhost'],
      rabbit_own_user     => $rabbit_hash['user'],
      rabbit_own_password => $rabbit_hash['password'],
      default_router      => 'murano-default-router',
      default_nameservers => pick($external_dns['dns_list'], '8.8.8.8'),
      service_host        => $api_bind_host,
      service_port        => $api_bind_port,
      external_network    => $external_network,
      use_trusts          => true,
    }

    class { '::murano::api':
      host    => $api_bind_host,
      port    => $api_bind_port,
      sync_db => false,
    }

    class { '::murano::engine':
      sync_db => false,
    }

    class { '::murano::client': }

    class { '::murano::dashboard':
      enable_glare => $enable_glare,
      repo_url     => $repository_url,
      sync_db      => false,
    }

    $haproxy_stats_url = "http://${management_ip}:10000/;csv"

    $murano_protocol = get_ssl_property($ssl_hash, {}, 'murano', 'internal', 'protocol', 'http')
    $murano_address  = get_ssl_property($ssl_hash, {}, 'murano', 'internal', 'hostname', [$service_endpoint, $management_vip])
    $murano_url      = "${murano_protocol}://${murano_address}:${api_bind_port}"

    $lb_defaults = { 'provider' => 'haproxy', 'url' => $haproxy_stats_url }

    if $external_lb {
      $lb_backend_provider = 'http'
      $lb_url = $murano_url
    }

    $lb_hash = {
      'murano-api'      => {
        name     => 'murano-api',
        provider => $lb_backend_provider,
        url      => $lb_url
      }
    }

    ::osnailyfacter::wait_for_backend {'murano-api':
      lb_hash     => $lb_hash,
      lb_defaults => $lb_defaults
    }

    Firewall[$firewall_rule] -> Class['::murano::api']
    Service['murano-api'] -> ::Osnailyfacter::Wait_for_backend['murano-api']

    # TODO (iberezovskiy): remove this workaround in N when murano module
    # will be switched to puppet-oslo usage for rabbit configuration
    if $kombu_compression in ['gzip','bz2'] {
      if !defined(Oslo::Messaging_rabbit['murano_config']) and !defined(Murano_config['oslo_messaging_rabbit/kombu_compression']) {
        murano_config { 'oslo_messaging_rabbit/kombu_compression': value => $kombu_compression; }
      } else {
        Murano_config<| title == 'oslo_messaging_rabbit/kombu_compression' |> { value => $kombu_compression }
      }
    }
  }

}
