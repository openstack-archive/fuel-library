# == Class: neutron::server
#
# Setup and configure the neutron API endpoint
#
# === Parameters
#
# [*sync_db*]
# (optional) Run neutron-db-manage on api nodes after installing the package.
# Defaults to false
#
class neutron::server (
  $neutron_config     = {},
  $primary_controller = false,
  $sync_db            = false,
  $nova_admin_tenant_id_mask = 'XXX_service_tenant_id_XXX',
  $nova_admin_tenant_name    = 'services',
) {
  include 'neutron::params'

  require 'keystone::python'

  Anchor['neutron-init-done'] ->
      Anchor['neutron-server']

  anchor {'neutron-server':}

  if $::neutron::params::server_package {
    $server_package = 'neutron-server'
    package {"$server_package":
      name   => $::neutron::params::server_package,
      ensure => $package_ensure
    }
  } else {
    $server_package = 'neutron'
  }
  if $::operatingsystem == 'Ubuntu' {
    # Package['neutron-server'] provides two services:
    # * neutron-server
    # * neutron-metadata-agent
    # because we need STOP neutron-metadata-agent here
    #
    file { '/etc/init/neutron-metadata-agent.override':
      replace => 'no',
      ensure  => 'present',
      content => 'manual',
      mode    => '0644',
    } -> Package["$server_package"]
    file { '/etc/init/neutron-server.override':
      replace => 'no',
      ensure  => 'present',
      content => 'manual',
      mode    => '0644',
    } -> Package["$server_package"]
    Package["$server_package"] ->
    exec { 'rm-neutron-server-override':
      path      => '/sbin:/bin:/usr/bin:/usr/sbin',
      command   => "rm -f /etc/init/neutron-server.override",
    }
    if $service_provider != 'pacemaker' {
      Package["$server_package"] ->
      exec { 'rm-neutron-metadata-override':
        path      => '/sbin:/bin:/usr/bin:/usr/sbin',
        command   => "rm -f /etc/init/neutron-metadata-agent.override",
      }
    }
  }
  Package[$server_package] -> Neutron_config<||>
  Package[$server_package] -> Neutron_api_config<||>

  if defined(Anchor['neutron-plugin-ovs']) {
    Package["$server_package"] -> Anchor['neutron-plugin-ovs']
  }

  Neutron_config<||> ~> Service['neutron-server']
  Neutron_api_config<||> ~> Service['neutron-server']
  Service <| title == 'mysql' |> -> Service['neutron-server']
  Service <| title == 'haproxy' |> -> Service['neutron-server']

  if $sync_db {
    if ($::neutron::params::server_package) {
      # Debian platforms
      Package<| title == 'neutron-server' |> ~> Exec['neutron-db-sync']
    } else {
      # RH platforms
      Package<| title == 'neutron' |> ~> Exec['neutron-db-sync']
    }
    exec { 'neutron-db-sync':
      command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
      path        => '/usr/bin',
      refreshonly => true,
    }
    Exec<| title=='neutron-db-sync' |> -> Service['neutron-server']
    Neutron_config<| title == 'database/connection' |> ~> Exec['neutron-db-sync']
    Neutron_config<||>      -> Exec['neutron-db-sync']
    Neutron_plugin_ovs<||>  -> Exec['neutron-db-sync']
    Neutron_plugin_ml2<||>  -> Exec['neutron-db-sync']
  }

  if $neutron_config['server']['api_workers'] {
     $api_workers = $neutron_config['server']['api_workers']
  }
  else {
     $api_workers = min($::processorcount + 0, 50 + 0)
  }

  if $neutron_config['server']['rpc_workers'] {
     $rpc_workers = $neutron_config['server']['rpc_workers']
  }
  else {
     $rpc_workers = min($::processorcount + 0, 50 + 0)
  }

  neutron_config {
    'DEFAULT/notify_nova_on_port_status_changes': value => $neutron_config['server']['notify_nova_on_port_status_changes'];
    'DEFAULT/notify_nova_on_port_data_changes': value => $neutron_config['server']['notify_nova_on_port_data_changes'];
    'DEFAULT/nova_url':             value => $neutron_config['server']['notify_nova_api_url'];
    'DEFAULT/nova_region_name':     value => $neutron_config['keystone']['auth_region'];
    'DEFAULT/nova_admin_username':  value => $neutron_config['server']['notify_nova_admin_username'];
    'DEFAULT/nova_admin_tenant_id': value => $nova_admin_tenant_id_mask;
    'DEFAULT/nova_admin_password':  value => $neutron_config['server']['notify_nova_admin_password'];
    'DEFAULT/nova_admin_auth_url':  value => $neutron_config['server']['notify_nova_admin_auth_url'];
    'DEFAULT/send_events_interval': value => $neutron_config['server']['notify_nova_send_events_interval'];
    'DEFAULT/api_workers':          value => $api_workers;
    'DEFAULT/rpc_workers':          value => $rpc_workers;
    'database/connection':          value => $neutron_config['database']['url'];
    'database/max_retries':         value => $neutron_config['database']['reconnects'];
    'database/reconnect_interval':  value => $neutron_config['database']['reconnect_interval'];
    'database/max_pool_size':       value => $neutron_config['database']['max_pool_size'];
    'database/max_overflow':        value => $neutron_config['database']['max_overflow'];
    'database/idle_timeout':        value => $neutron_config['database']['idle_timeout'];
  }

  neutron_api_config {
    'filter:authtoken/auth_url':          value => $neutron_config['keystone']['auth_url'];
    'filter:authtoken/auth_host':         value => $neutron_config['keystone']['auth_host'];
    'filter:authtoken/auth_port':         value => $neutron_config['keystone']['auth_port'];
    'filter:authtoken/auth_protocol':     value => $neutron_config['keystone']['auth_protocol'];
    'filter:authtoken/admin_tenant_name': value => $neutron_config['keystone']['admin_tenant_name'];
    'filter:authtoken/admin_user':        value => $neutron_config['keystone']['admin_user'];
    'filter:authtoken/admin_password':    value => $neutron_config['keystone']['admin_password'];
  }

  Neutron_config<||> -> Exec['get_service_tenant_ID']
  File['/root/openrc'] -> Exec['get_service_tenant_ID']

  Keystone_tenant["${nova_admin_tenant_name}"] -> Exec['get_service_tenant_ID']
  Keystone_user_role["${neutron_config['keystone']['admin_user']}@${nova_admin_tenant_name}"] -> Exec['get_service_tenant_ID']
  Keystone_endpoint<| title == "${neutron_config['keystone']['admin_user']}" |> -> Exec['get_service_tenant_ID']

  Openstack::Ha::Haproxy_service<| title == 'keystone-1' |> -> Exec['get_service_tenant_ID']
  Openstack::Ha::Haproxy_service<| title == 'keystone-2' |> -> Exec['get_service_tenant_ID']
  exec {'get_service_tenant_ID':  # Imitate tries & try_sleep for 'onlyif'
    tries     => 10,                  # by using couple of execs
    try_sleep => 3,               # WITHOUT refreshonly option
    command   => "bash -c \"source /root/openrc ; keystone tenant-list\" | grep \"${nova_admin_tenant_name}\" > /tmp/services",
    path      => '/usr/sbin:/usr/bin:/sbin:/bin'
  }
  # do not use refreshonly and notify here -- it leads to double execution 'onlyif' command
  exec {'insert_service_tenant_ID':
    onlyif  => "head -n1 /tmp/services | awk -F'|' '{print \$2}' | grep -xEe '\\s*[[:xdigit:]]+\\s*' > /tmp/serviceid",
    command => "sed -e \"s/${nova_admin_tenant_id_mask}/`head -n1 /tmp/serviceid`/g\" -i /etc/neutron/neutron.conf",
    path => '/usr/sbin:/usr/bin:/sbin:/bin'
  }
  Exec['get_service_tenant_ID'] -> Exec['insert_service_tenant_ID'] -> Service<| title == 'neutron-server' |>

  anchor {'neutron-server-config-done':}

  service {'neutron-server':
    name       => $::neutron::params::server_service,
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::neutron::params::service_provider,
  }

  anchor {'neutron-api-up':}

  Anchor['neutron-server'] ->
    Neutron_config<||> ->
      Neutron_api_config<||> ->
  Anchor['neutron-server-config-done'] ->
    Service['neutron-server'] ->
  Anchor['neutron-api-up'] ->
  Anchor['neutron-server-done']

  Package[$server_package] -> class { 'neutron::quota': } -> Anchor['neutron-server-config-done']

  if $primary_controller {
    Anchor['neutron-api-up'] ->
    class { 'neutron::network::predefined_networks':
      neutron_config => $neutron_config,
    } -> Anchor['neutron-server-done']
  }

  anchor {'neutron-server-done':}
  Package<| title == $server_package|> ~> Service<| title == 'neutron-server'|>
  if !defined(Service['neutron-server']) {
    notify{ "Module ${module_name} cannot notify service neutron-server on package update": }
  }
}
