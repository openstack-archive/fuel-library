# == Class: nailgun::client
# Configures the fuel client.

class nailgun::client (
  $server        = '127.0.0.1',
  $port          = '8000',
  $keystone_user = 'admin',
  $keystone_pass = 'admin',
  $keystone_port = '5000',
) {
  include nailgun::packages

  exec { 'fuel_client_config' :
    command => 'fuel',
    path    => '/usr/bin',
  }

  file_line { 'replace keystone user with the actual user':
    ensure  => present,
    path    => '/root/.config/fuel_client.yaml',
    line    => "KEYSTONE_USER: ${$keystone_user}",
    match   => '^KEYSTONE_USER:',
    require => Exec['fuel_client_config'],
  }

  file_line { 'replace keystone password with the actual password':
    ensure  => present,
    path    => '/root/.config/fuel_client.yaml',
    line    => "KEYSTONE_PASS: ${$keystone_pass}",
    match   => '^KEYSTONE_PASS:',
    require => Exec['fuel_client_config'],
  }
}
