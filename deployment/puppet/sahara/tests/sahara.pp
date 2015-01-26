class { 'sahara' :
  enabled             => true,
  db_password         => 'secret',
  use_neutron         => true,
  use_floating_ips    => true,
  openstack_version   => '2014.1.0-6',
}
