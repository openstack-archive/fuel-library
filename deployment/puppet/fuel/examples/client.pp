$fuel_settings = parseyaml($astute_settings_yaml)

class { "fuel::nailgun::client":
  server_address     => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  keystone_user      => $::fuel_settings['FUEL_ACCESS']['user'],
  keystone_password  => $::fuel_settings['FUEL_ACCESS']['password'],
  keystone_port      => 5000,
}
