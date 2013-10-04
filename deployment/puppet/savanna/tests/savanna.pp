class { 'savanna' :
  savanna_enabled     => true,
  savanna_db_password => 'secret',
  use_neutron         => true,
  use_floating_ips    => true,
}