class { 'sahara' :
  enabled             => true,
  db_password         => 'secret',
  use_neutron         => true,
}
