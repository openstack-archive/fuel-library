class { 'L23network::Params':
  name => 'L23network::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Stdlib::Stages':
  name => 'Stdlib::Stages',
}

class { 'Stdlib':
  name => 'Stdlib',
}

class { 'main':
  name => 'main',
}

l23_stored_config { 'br-fw-admin':
  ensure  => 'present',
  before  => ['L3_ifconfig[br-fw-admin]', 'L2_port[br-fw-admin]'],
  gateway => 'absent',
  ipaddr  => '10.122.5.4/24',
  method  => 'static',
  name    => 'br-fw-admin',
}

l23_stored_config { 'br-mgmt':
  ensure  => 'present',
  before  => ['L3_ifconfig[br-mgmt]', 'L2_port[br-mgmt]'],
  gateway => '10.122.7.6',
  ipaddr  => '10.122.7.3/24',
  method  => 'static',
  name    => 'br-mgmt',
}

l23network::l2::port { 'br-fw-admin':
  ensure => 'present',
  before => 'L3_ifconfig[br-fw-admin]',
  name   => 'br-fw-admin',
  port   => 'br-fw-admin',
}

l23network::l2::port { 'br-mgmt':
  ensure => 'present',
  before => 'L3_ifconfig[br-mgmt]',
  name   => 'br-mgmt',
  port   => 'br-mgmt',
}

l23network::l3::ifconfig { 'br-fw-admin':
  ensure                => 'present',
  check_by_ping         => 'gateway',
  check_by_ping_timeout => '30',
  gateway               => 'absent',
  interface             => 'br-fw-admin',
  ipaddr                => '10.122.5.4/24',
  name                  => 'br-fw-admin',
}

l23network::l3::ifconfig { 'br-mgmt':
  ensure                => 'present',
  check_by_ping         => 'gateway',
  check_by_ping_timeout => '30',
  gateway               => '10.122.7.6',
  interface             => 'br-mgmt',
  ipaddr                => '10.122.7.3/24',
  name                  => 'br-mgmt',
  require               => 'L23network::L3::Ifconfig[br-fw-admin]',
}

l2_port { 'br-fw-admin':
  ensure    => 'present',
  interface => 'br-fw-admin',
}

l2_port { 'br-mgmt':
  ensure    => 'present',
  interface => 'br-mgmt',
}

l3_ifconfig { 'br-fw-admin':
  ensure    => 'present',
  gateway   => 'absent',
  interface => 'br-fw-admin',
  ipaddr    => '10.122.5.4/24',
}

l3_ifconfig { 'br-mgmt':
  ensure    => 'present',
  gateway   => '10.122.7.6',
  interface => 'br-mgmt',
  ipaddr    => '10.122.7.3/24',
}

stage { 'deploy':
  name => 'deploy',
}

stage { 'deploy_app':
  before => 'Stage[deploy]',
  name   => 'deploy_app',
}

stage { 'deploy_infra':
  before => 'Stage[setup_app]',
  name   => 'deploy_infra',
}

stage { 'main':
  name => 'main',
}

stage { 'runtime':
  before  => 'Stage[setup_infra]',
  name    => 'runtime',
  require => 'Stage[main]',
}

stage { 'setup':
  before => 'Stage[main]',
  name   => 'setup',
}

stage { 'setup_app':
  before => 'Stage[deploy_app]',
  name   => 'setup_app',
}

stage { 'setup_infra':
  before => 'Stage[deploy_infra]',
  name   => 'setup_infra',
}

