#
class neutron::server (
  $neutron_config     = {},
  $primary_controller = false,
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

  neutron_config {
    'database/sql_connection':      value => $neutron_config['database']['url'];
    'database/sql_max_retries':     value => $neutron_config['database']['reconnects'];
    'database/reconnect_interval':  value => $neutron_config['database']['reconnect_interval'];
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

  anchor {'neutron-server-config-done':}

  File<| title=='neutron-logging.conf' |> ->
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
}

# vim: set ts=2 sw=2 et :
