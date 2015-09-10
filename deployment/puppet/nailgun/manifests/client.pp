class nailgun::client (
$server = '127.0.0.1',
$port   = '8000',
$keystone_user = 'admin',
$keystone_pass = 'admin',
$keystone_port = '5000',
)
{
  include nailgun::packages

  file { '/etc/skel/.config':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => 0700,
  }
  file { '/root/.config':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => 0700,
  }
  file { '/etc/skel/.config/fuelclient.yaml':
    require => file['/etc/skel/.config'],
    content => template('nailgun/fuelclient.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => 0700,
  }
  file { '/root/.config/fuelclient.yaml':
    require => file['/root/.config'],
    content => template('nailgun/fuelclient.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => 0700,
  }
  file_line { 'fuel client config file env variable for root user':
    line => 'export FUELCLIENT_CUSTOM_SETTINGS="~/.config/fuelclient.yaml"',
    path => '/root/.bashrc',
  }
  file_line { 'fuel client config file env variable':
    line => 'export FUELCLIENT_CUSTOM_SETTINGS="~/.config/fuelclient.yaml"',
    path => '/etc/skel/.bashrc',
  }
}
