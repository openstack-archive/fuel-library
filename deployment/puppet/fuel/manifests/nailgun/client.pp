class fuel::nailgun::client (
  $server_address            = $::fuel::params::nailgun_host,
  $server_port               = $::fuel::params::nailgun_port,
  $keystone_port             = $::fuel::params::keystone_port,
  $keystone_user             = $::fuel::params::keystone_admin_user,
  $keystone_password         = $::fuel::params::keystone_admin_password,
  $keystone_tenant           = $::fuel::params::keystone_admin_tenant,
  $auth_url                  = "http://$server_address:$server_port/keystone/v2.0",
  ) inherits fuel::params {

  ensure_packages(["python-fuelclient"])

  file {['/root/.config',
         '/root/.config/fuel']:
    ensure => directory
  }

  file { "/root/.config/fuel/fuel_client.yaml":
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template("fuel/nailgun/client.yaml.erb"),
    require => File['/root/.config/fuel'],
  }

}
