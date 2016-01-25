class fuel::nailgun::client (
  $server_address            = $::fuel::params::nailgun_host,
  $server_port               = $::fuel::params::nailgun_port,
  $keystone_port             = $::fuel::params::keystone_port,
  $keystone_user             = $::fuel::params::keystone_admin_user,
  $keystone_password         = $::fuel::params::keystone_admin_password,
  ) inherits fuel::params {

  package { "python-fuelclient": }

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

  # This exec needs python-fuelclient to be installed and nailgun running
  # Probably this should be moved to a separate task
  exec {'sync_deployment_tasks':
    command   => 'fuel rel --sync-deployment-tasks --dir /etc/puppet/',
    path      => '/usr/bin',
    tries     => 12,
    try_sleep => 10,
  }
}
