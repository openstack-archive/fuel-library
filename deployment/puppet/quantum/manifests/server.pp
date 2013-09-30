#
class quantum::server (
  $auth_password,
  $package_ensure   = 'present',
  $enabled          = true,
  $auth_type        = 'keystone',
  $auth_host        = 'localhost',
  $auth_port        = '35357',
  $auth_tenant      = 'services',
  $auth_user        = 'quantum'
) {
  include 'quantum::params'

  require 'keystone::python'

  Anchor['quantum-init-done'] -> 
      Anchor['quantum-server']

  anchor {'quantum-server':}

  if $::operatingsystem == 'Ubuntu' {
       file { "/etc/init/quantum-metadata-agent.override":
         replace => "no",
         ensure  => "present",
         content => "manual",
         mode    => 644,
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
    'filter:authtoken/auth_host':         value => $auth_host;
    'filter:authtoken/auth_port':         value => $auth_port;
    'filter:authtoken/admin_tenant_name': value => $auth_tenant;
    'filter:authtoken/admin_user':        value => $auth_user;
    'filter:authtoken/admin_password':    value => $auth_password;
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  File<| title=='quantum-logging.conf' |> ->
  service {'quantum-server':
    name       => $::quantum::params::server_service,
    ensure     => $service_ensure,
    enable     => $enabled,
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
  anchor {'quantum-server-done':}
  Anchor['quantum-server'] -> Anchor['quantum-server-done']
}
