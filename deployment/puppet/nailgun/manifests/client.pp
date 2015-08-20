class nailgun::client (
$server = '127.0.0.1',
$port   = '8000',
$keystone_user = 'admin',
$keystone_pass = 'admin',
$keystone_port = '5000',
)
{
  include nailgun::packages

  file { '/root/.config':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/etc/skel/.config':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/root/.config/fuelclient.yaml':
    require => file['/root/.config'],
    content => template('nailgun/fuelclient.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  file { '/etc/skel/.config/fuelclient.yaml':
    require => file['/etc/skel/.config'],
    content => template('nailgun/fuelclient.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  file { '/root/.bashrc':
    content => template('nailgun/bashrc.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
  }
  file_line { 'fuel client config file env variable':
    line => 'export FUELCLIENT_CUSTOM_SETTINGS="/root/.config/fuelclient.yaml"',
    path => '/etc/skel/.bashrc',
  }
}
