class nailgun::client (
$server = '127.0.0.1',
$port   = '8000',
$keystone_user = 'admin',
$keystone_pass = 'admin',
$keystone_port = '5000',
)
{
  include nailgun::packages

  file { '/root/.fuel-config':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/etc/skel/.fuel-config':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/root/.fuel-config/fuelclient.yaml':
    require => file['/root/.fuel-config'],
    content => template('nailgun/fuelclient.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  file { '/etc/skel/.fuel-config/fuelclient.yaml':
    require => file['/etc/skel/.fuel-config'],
    content => template('nailgun/fuelclient.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  file_line { 'fuel client config file env variable for root user':
    line => 'export FUELCLIENT_CUSTOM_SETTINGS="~/.fuel-config/fuelclient.yaml"',
    path => '/root/.bashrc',
  }
  file_line { 'fuel client config file env variable':
    line => 'export FUELCLIENT_CUSTOM_SETTINGS="~/.fuel-config/fuelclient.yaml"',
    path => '/etc/skel/.bashrc',
  }
}
