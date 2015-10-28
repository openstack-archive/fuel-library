class { 'Openstack::Workloads_collector':
  enabled               => 'true',
  name                  => 'Openstack::Workloads_collector',
  workloads_create_user => 'true',
  workloads_password    => 'xOa1RAu5',
  workloads_tenant      => 'services',
  workloads_username    => 'fuel_stats_user',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

haproxy_backend_status { 'keystone-admin':
  before => 'Class[Openstack::Workloads_collector]',
  count  => '200',
  name   => 'keystone-2',
  step   => '6',
  url    => 'http://172.16.1.2:10000/;csv',
}

keystone_user { 'fuel_stats_user':
  ensure   => 'present',
  enabled  => 'true',
  name     => 'fuel_stats_user',
  password => 'xOa1RAu5',
  tenant   => 'services',
}

keystone_user_role { 'fuel_stats_user@services':
  ensure => 'present',
  name   => 'fuel_stats_user@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

