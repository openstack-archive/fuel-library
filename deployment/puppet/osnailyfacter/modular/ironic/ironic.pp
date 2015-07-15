notice('MODULAR: ironic.pp')

$ironic_hash                = hiera('ironic')
$nova_hash                  = hiera('nova')
$access_hash                = hiera_hash('access',{})
$public_vip                 = hiera('public_vip')
$management_vip             = hiera('management_vip')
$baremetal_vip              = hiera('baremetal_vip')
$internal_address           = hiera('internal_address')
$service_endpoint           = hiera('service_endpoint', $management_vip)
$database_vip               = hiera('database_vip', $service_endpoint)
$keystone_endpoint          = hiera('keystone_endpoint', $service_endpoint)
$neutron_endpoint           = hiera('neutron_endpoint', $service_endpoint)
$glance_api_servers         = hiera('glance_api_servers', "${service_endpoint}:9292")
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$syslog_log_facility_ironic = hiera('syslog_log_facility_ironic', 'LOG_USER')
$rabbit_hash                = hiera('rabbit_hash')
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_hosts               = split($amqp_hosts, ',')
$controllers                = hiera('controllers')
$neutron_config             = hiera('quantum_settings')
$neutron_net                = $neutron_config['predefined_networks']['baremetal']

$db_host                    = pick($ironic_hash['db_host'], $database_vip)
$db_user                    = pick($ironic_hash['db_user'], 'ironic')
$db_name                    = pick($ironic_hash['db_name'], 'ironic')
$db_password                = pick($ironic_hash['db_password'], 'ironic')
$database_connection        = "mysql://${db_name}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

$ironic_tenant              = pick($ironic_hash['tenant'],'services')
$ironic_user                = pick($ironic_hash['user'],'ironic')
$ironic_user_password       = $ironic_hash['user_password']
$ironic_swift_tempurl_key   = $ironic_hash['swift_tempurl_key']

$os_auth_url                = "http://${keystone_endpoint}:5000/v2.0"
$os_tenant_name             = $access_hash['tenant']
$os_username                = $access_hash['user']
$os_password                = $access_hash['password']

$swift_cmd_prefix           = "/usr/bin/swift --os-auth-url ${os_auth_url} --os-tenant-name ${ironic_tenant} --os-username ${ironic_user} --os-password ${ironic_user_password}"
$glance_cmd_prefix          = "/usr/bin/glance --os-auth-url ${os_auth_url} --os-tenant-name ${os_tenant_name} --os-username ${os_username} --os-password ${os_password}"

if $ironic_hash['enabled'] {
  class { 'ironic':
    verbose                     => $verbose,
    debug                       => $debug,
    enabled_drivers             => ['fuel_ssh'],
    rabbit_hosts                => $rabbit_hosts,
    rabbit_port                 => 5673,
    rabbit_userid               => $rabbit_hash['user'],
    rabbit_password             => $rabbit_hash['password'],
    amqp_durable_queues         => $rabbit_ha_queues,
    use_syslog                  => $use_syslog,
    log_facility                => $syslog_log_facility_ironic,
    database_connection         => $database_connection,
    glance_api_servers          => $glance_api_servers,
  }

  class { 'ironic::client': }

  class { 'ironic::api':
    host_ip           => $internal_address,
    auth_host         => $keystone_endpoint,
    admin_tenant_name => $ironic_tenant,
    admin_user        => $ironic_user,
    admin_password    => $ironic_user_password,
    neutron_url       => "http://${neutron_endpoint}:9696",
  }

  firewall { '207 ironic-api' :
    dport   => '6385',
    proto   => 'tcp',
    action  => 'accept',
  }

  openstack::ha::haproxy_service { 'swift-baremetal':
    order                  => '125',
    listen_port            => 8080,
    server_names           => filter_hash($controllers, 'name'),
    ipaddresses            => filter_hash($controllers, 'storage_address'),
    public_virtual_ip      => false,
    internal_virtual_ip    => $baremetal_vip,
    haproxy_config_options => {
      'option' => ['httpchk', 'httplog', 'httpclose'],
    },
    balancermember_options => 'check port 49001 inter 15s fastinter 2s downinter 8s rise 3 fall 3',
  }

  openstack::ha::haproxy_service { 'ironic-api':
    order                  => '180',
    listen_port            => 6385,
    require_service        => 'ironic-api',
    server_names           => filter_hash($controllers, 'name'),
    ipaddresses            => filter_hash($controllers, 'internal_address'),
    internal_virtual_ip    => $management_vip,
    public_virtual_ip      => $public_vip,
    haproxy_config_options => {
	option => ['httpchk GET /', 'httplog','httpclose'],
    },
  }

  openstack::ha::haproxy_service { 'ironic-baremetal':
    order                  => '185',
    listen_port            => 6385,
    require_service        => 'ironic-api',
    server_names           => filter_hash($controllers, 'name'),
    ipaddresses            => filter_hash($controllers, 'internal_address'),
    public_virtual_ip      => false,
    internal_virtual_ip    => $baremetal_vip,
    haproxy_config_options => {
	option => ['httpchk GET /', 'httplog','httpclose'],
    },
  }

  openstack::network::create_network{'baremetal':
    netdata => $neutron_net,
  } ->
  neutron_router_interface { "router04:baremetal__subnet":
    ensure => present,
  }

  exec { 'upload-ironic-deploy-kernel':
    command => "${glance_cmd_prefix} image-create --name ironic_deploy_kernel --is-public True --container-format aki --location http://10.20.0.2:8080/bootstrap/linux",
    unless => "${glance_cmd_prefix} image-show ironic_deploy_kernel",
  }

  exec { 'upload-ironic-deploy-initramfs':
    command => "${glance_cmd_prefix} image-create --name ironic_deploy_initramfs --is-public True --container-format ari --location http://10.20.0.2:8080/bootstrap/initramfs.img",
    unless => "${glance_cmd_prefix} image-show ironic_deploy_initramfs",
  }

  exec { 'ironic-register-swift-tempurl-key':
    command => "${swift_cmd_prefix} post -m 'Temp-URL-Key:${ironic_swift_tempurl_key}'",
  }
}
