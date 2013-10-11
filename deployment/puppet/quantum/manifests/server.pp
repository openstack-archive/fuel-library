#
class quantum::server (
  $quantum_config     = {},
  $primary_controller = false,
) {
  include 'quantum::params'

  require 'keystone::python'

  Anchor['quantum-init-done'] ->
      Anchor['quantum-server']

  anchor {'quantum-server':}

  if $::operatingsystem == 'Ubuntu' {
    if $service_provider == 'pacemaker' {
       file { "/etc/init/quantum-metadata-agent.override":
         replace => "no",
         ensure  => "present",
         content => "manual",
         mode    => 644,
         before  => Package['quantum-server'],
       }
    }
  }

  if $::quantum::params::server_package {
    $server_package = 'quantum-server'

    package {$server_package:
      name   => $::quantum::params::server_package,
      ensure => $package_ensure
    }
  } else {
    $server_package = 'quantum'
  }

  Package[$server_package] -> Quantum_config<||>
  Package[$server_package] -> Quantum_api_config<||>

  if defined(Anchor['quantum-plugin-ovs']) {
    Package["$server_package"] -> Anchor['quantum-plugin-ovs']
  }

  Quantum_config<||> ~> Service['quantum-server']
  Quantum_api_config<||> ~> Service['quantum-server']

  quantum_api_config {
    'filter:authtoken/auth_url':          value => $quantum_config['keystone']['auth_url'];
    'filter:authtoken/auth_host':         value => $quantum_config['keystone']['auth_host'];
    'filter:authtoken/auth_port':         value => $quantum_config['keystone']['auth_port'];
    'filter:authtoken/admin_tenant_name': value => $quantum_config['keystone']['admin_tenant_name'];
    'filter:authtoken/admin_user':        value => $quantum_config['keystone']['admin_user'];
    'filter:authtoken/admin_password':    value => $quantum_config['keystone']['admin_password'];
  }

  File<| title=='quantum-logging.conf' |> ->
  service {'quantum-server':
    name       => $::quantum::params::server_service,
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::quantum::params::service_provider,
  }

  Anchor['quantum-server'] ->
      Quantum_config<||> ->
        Quantum_api_config<||> ->
  Anchor['quantum-server-config-done'] ->
     Service['quantum-server'] ->
  Anchor['quantum-server-done']

  # if defined(Anchor['quantum-plugin-ovs-done']) {
  #   Anchor['quantum-server-config-done'] ->
  #     Anchor['quantum-plugin-ovs-done'] ->
  #       Anchor['quantum-server-done']
  # }

  anchor {'quantum-server-config-done':}

  if $primary_controller {
    Anchor['quantum-server-config-done'] ->
    class { 'quantum::network::predefined_netwoks':
      quantum_config => $quantum_config,
    } -> Anchor['quantum-server-done']
    Service['quantum-server'] -> Class['quantum::network::predefined_netwoks']
  }

  anchor {'quantum-server-done':}
  Anchor['quantum-server'] -> Anchor['quantum-server-done']
}

# vim: set ts=2 sw=2 et :
