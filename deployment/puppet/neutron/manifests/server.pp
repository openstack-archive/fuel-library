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

  if $::operatingsystem == 'Ubuntu' {
    if $service_provider == 'pacemaker' {
       file { "/etc/init/neutron-metadata-agent.override":
         replace => "no",
         ensure  => "present",
         content => "manual",
         mode    => 644,
         before  => Package['neutron-server'],
       }
    } else {
       file { '/etc/init/neutron-metadata-agent.override':
         replace => 'no',
         ensure => 'present',
         content => 'manual',
         mode => 644,
       } -> Package['neutron-metadata-agent'] ->
       exec { 'rm-neutron-metadata-agent-override':
         path => '/sbin:/bin:/usr/bin:/usr/sbin',
         command => "rm -f /etc/init/neutron-metadata-agent.override",
       }
    }
  }

  if $::neutron::params::server_package {
    $server_package = 'neutron-server'

    package {$server_package:
      name   => $::neutron::params::server_package,
      ensure => $package_ensure
    }
  } else {
    $server_package = 'neutron'
  }

  Package[$server_package] -> Neutron_config<||>
  Package[$server_package] -> Neutron_api_config<||>

  if defined(Anchor['neutron-plugin-ovs']) {
    Package["$server_package"] -> Anchor['neutron-plugin-ovs']
  }

  Neutron_config<||> ~> Service['neutron-server']
  Neutron_api_config<||> ~> Service['neutron-server']

  neutron_api_config {
    'filter:authtoken/auth_url':          value => $neutron_config['keystone']['auth_url'];
    'filter:authtoken/auth_host':         value => $neutron_config['keystone']['auth_host'];
    'filter:authtoken/auth_port':         value => $neutron_config['keystone']['auth_port'];
    'filter:authtoken/admin_tenant_name': value => $neutron_config['keystone']['admin_tenant_name'];
    'filter:authtoken/admin_user':        value => $neutron_config['keystone']['admin_user'];
    'filter:authtoken/admin_password':    value => $neutron_config['keystone']['admin_password'];
  }

  File<| title=='neutron-logging.conf' |> ->
  service {'neutron-server':
    name       => $::neutron::params::server_service,
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::neutron::params::service_provider,
  }

  Anchor['neutron-server'] ->
      Neutron_config<||> ->
        Neutron_api_config<||> ->
  Anchor['neutron-server-config-done'] ->
     Service['neutron-server'] ->
  Anchor['neutron-server-done']

  # if defined(Anchor['neutron-plugin-ovs-done']) {
  #   Anchor['neutron-server-config-done'] ->
  #     Anchor['neutron-plugin-ovs-done'] ->
  #       Anchor['neutron-server-done']
  # }

  anchor {'neutron-server-config-done':}

  if $primary_controller {
    Anchor['neutron-server-config-done'] ->
    class { 'neutron::network::predefined_netwoks':
      neutron_config => $neutron_config,
    } -> Anchor['neutron-server-done']
    Service['neutron-server'] -> Class['neutron::network::predefined_netwoks']
  }

  anchor {'neutron-server-done':}
  Anchor['neutron-server'] -> Anchor['neutron-server-done']
}

# vim: set ts=2 sw=2 et :
