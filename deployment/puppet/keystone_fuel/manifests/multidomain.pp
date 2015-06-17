class keysone_fuel::multidomain {
  $domain_config_dir = '/etc/keystone/domains'

  file { 'domain-config-dir' :
    ensure => 'directory',
    path   => $domain_config_dir,
  }

  keystone_config {
    'identity/domain_specific_drivers_enabled' : value => true;
    'identity/domain_config_dir' :               value => $domain_config_dir;
  }
}
