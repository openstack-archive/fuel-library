class { 'Settings':
  name => 'Settings',
}

class { 'Sysctl::Base':
  name => 'Sysctl::Base',
}

class { 'main':
  name => 'main',
}

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
}

package { 'python-openstackclient':
  ensure => 'installed',
  name   => 'python-openstackclient',
}

stage { 'main':
  name => 'main',
}

sysctl::value { 'vm.swappiness':
  key     => 'vm.swappiness',
  name    => 'vm.swappiness',
  require => 'Class[Sysctl::Base]',
  value   => '10',
}

sysctl { 'vm.swappiness':
  before => 'Sysctl_runtime[vm.swappiness]',
  name   => 'vm.swappiness',
  val    => '10',
}

sysctl_runtime { 'vm.swappiness':
  name => 'vm.swappiness',
  val  => '10',
}

