# == Class: nailgun::client
# Configures the fuel client.

class nailgun::client (
  $server        = '127.0.0.1',
  $port          = '8000',
  $keystone_user = 'admin',
  $keystone_pass = 'admin',
  $keystone_port = '5000',
) {
  $config_path = '/root/.config/fuel'

  exec { "mkdir -p ${config_path}":
    path   => ['/bin', '/usr/bin'],
    unless => "test -d ${config_path}",
  }

  file { "${config_path}/fuel_client.yaml":
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template("${module_name}/fuel_client.yaml.erb"),
    require => Exec["mkdir -p ${config_path}"],
  }
}
