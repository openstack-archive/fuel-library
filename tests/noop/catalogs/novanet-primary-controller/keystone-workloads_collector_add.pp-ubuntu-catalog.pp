class { 'Openstack::Workloads_collector':
  enabled               => 'true',
  name                  => 'Openstack::Workloads_collector',
  workloads_create_user => 'true',
  workloads_password    => 'MhdNr1K7',
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
  url    => 'http://192.168.0.5:10000/;csv',
}

keystone_user { 'workloads_collector':
  ensure   => 'present',
  enabled  => 'true',
  name     => 'workloads_collector',
  password => 'MhdNr1K7',
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

