class openstack_tasks::sahara::sahara {

  notice('MODULAR: sahara/sahara.pp')

  prepare_network_config(hiera_hash('network_scheme', {}))

  $sahara_hash                = hiera_hash('sahara', {})
  $rabbit_hash                = hiera_hash('rabbit', {})
  $public_ssl_hash            = hiera_hash('public_ssl')
  $ceilometer_hash            = hiera_hash('ceilometer', {})
  $primary_controller         = hiera('primary_controller')
  $public_vip                 = hiera('public_vip')
  $database_vip               = hiera('database_vip', undef)
  $management_vip             = hiera('management_vip')
  $neutron_config             = hiera_hash('neutron_config')
  $service_endpoint           = hiera('service_endpoint')
  $syslog_log_facility_sahara = hiera('syslog_log_facility_sahara')
  $debug                      = pick($sahara_hash['debug'], hiera('debug', false))
  $default_log_levels         = hiera_hash('default_log_levels')
  $use_syslog                 = hiera('use_syslog', true)
  $use_stderr                 = hiera('use_stderr', false)
  $rabbit_ha_queues           = hiera('rabbit_ha_queues')
  $external_lb                = hiera('external_lb', false)
  $ssl_hash                   = hiera_hash('use_ssl', {})
  $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $internal_auth_url          = "${internal_auth_protocol}://${internal_auth_address}:5000"
  $admin_identity_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_uri         = "${admin_identity_protocol}://${admin_identity_address}:35357"
  $kombu_compression          = hiera('kombu_compression', $::os_service_default)
  $memcached_servers          = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')

  #################################################################

  if $sahara_hash['enabled'] {
    $firewall_rule   = '201 sahara-api'
    $api_bind_port   = '8386'
    $api_bind_host   = get_network_role_property('sahara/api', 'ipaddr')
    $public_address = $public_ssl_hash['services'] ? {
      true    => $public_ssl_hash['hostname'],
      default => $public_vip,
    }
    $public_protocol = $public_ssl_hash['services'] ? {
      true    => 'https',
      default => 'http',
    }
    $sahara_user     = pick($sahara_hash['user'], 'sahara')
    $sahara_password = pick($sahara_hash['user_password'])
    $tenant          = pick($sahara_hash['tenant'], 'services')
    $max_pool_size   = min($::os_workers * 5 + 0, 30 + 0)
    $max_overflow    = min($::os_workers * 5 + 0, 60 + 0)
    $max_retries     = '-1'
    $idle_timeout    = '3600'

    $db_type         = pick($sahara_hash['db_type'], 'mysql+pymysql')
    $db_user         = pick($sahara_hash['db_user'], 'sahara')
    $db_name         = pick($sahara_hash['db_name'], 'sahara')
    $db_password     = pick($sahara_hash['db_password'])
    $db_host         = pick($sahara_hash['db_host'], $database_vip)
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

    ####### Disable upstart startup on install #######
    tweaks::ubuntu_service_override { 'sahara-api': }

    firewall { $firewall_rule :
      dport  => $api_bind_port,
      proto  => 'tcp',
      action => 'accept',
    }

    class { '::sahara' :
      host                   => $api_bind_host,
      port                   => $api_bind_port,
      debug                  => $debug,
      use_syslog             => $use_syslog,
      use_stderr             => $use_stderr,
      plugins                => [ 'ambari', 'cdh', 'mapr', 'spark', 'vanilla' ],
      log_facility           => $syslog_log_facility_sahara,
      database_connection    => $db_connection,
      database_max_pool_size => $max_pool_size,
      database_max_overflow  => $max_overflow,
      database_max_retries   => $max_retries,
      database_idle_timeout  => $idle_timeout,
      default_transport_url  => $transport_url,
      sync_db                => $primary_controller,
      auth_uri               => "${internal_auth_url}/v2.0/",
      identity_uri           => $admin_identity_uri,
      use_neutron            => true,
      admin_user             => $sahara_user,
      admin_password         => $sahara_password,
      admin_tenant_name      => $tenant,
      rabbit_ha_queues       => $rabbit_ha_queues,
      kombu_compression      => $kombu_compression,
      memcached_servers      => $local_memcached_server,
    }

    if $public_ssl_hash['services'] {
      file { '/etc/pki/tls/certs':
        mode => '0755',
      }

      file { '/etc/pki/tls/certs/public_haproxy.pem':
        mode => '0644',
      }

      sahara_config {
        'object_store_access/public_identity_ca_file':     value => '/etc/pki/tls/certs/public_haproxy.pem';
        'object_store_access/public_object_store_ca_file': value => '/etc/pki/tls/certs/public_haproxy.pem';
      }
    }

    class { '::sahara::service::api': }

    class { '::sahara::service::engine': }

    # TODO degorenko: move this to upstream module, when RDO & UCA will prepare sahara-dashboard package
    if $::os_package_type == 'debian' {
      package { 'sahara-dashboard':
        name   => 'python-sahara-dashboard',
        ensure => present,
      }
    }

    class { '::sahara::client': }

    if $ceilometer_hash['enabled'] {
      class { '::sahara::notify':
        notification_driver => $ceilometer_hash['notification_driver'],
      }
    }

    Firewall[$firewall_rule] -> Class['::sahara::service::api']
  }

}
