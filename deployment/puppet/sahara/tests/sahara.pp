class { 'sahara' :
  sahara_enabled      => true,
  sahara_db_password  => 'secret',
  use_neutron         => true,
  use_floating_ips    => true,
}
