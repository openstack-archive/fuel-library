class { 'Openstack::Workloads_collector':
  enabled               => 'true',
  name                  => 'Openstack::Workloads_collector',
  workloads_create_user => 'true',
  workloads_password    => '1r3ROjcQ',
  workloads_tenant      => 'services',
  workloads_username    => 'workloads_collector',
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
  url    => 'http://192.168.0.2:10000/;csv',
}

keystone_user { 'workloads_collector':
  ensure   => 'present',
  enabled  => 'true',
  name     => 'workloads_collector',
  password => '1r3ROjcQ',
  tenant   => 'services',
}

keystone_user_role { 'workloads_collector@services':
  ensure => 'present',
  name   => 'workloads_collector@services',
  roles  => 'admin',
}

stage { 'main':
  name => 'main',
}

