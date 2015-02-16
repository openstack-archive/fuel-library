class nailgun::host::nailgun(
  $confdir,

  $database_name,
  $database_engine,
  $database_host,
  $database_port,
  $database_user,
  $database_passwd,

  $staticdir,
  $templatedir,

  $rabbitmq_host,
  $rabbitmq_astute_user,
  $rabbitmq_astute_password,

  $admin_network,
  $admin_network_cidr,
  $admin_network_size,
  $admin_network_first,
  $admin_network_last,
  $admin_network_netmask,
  $admin_network_mac,
  $admin_network_ip,

  $cobbler_host,
  $cobbler_url,
  $cobbler_user = "cobbler",
  $cobbler_password = "cobbler",

  $mco_pskey,
  $mco_vhost,
  $mco_host,
  $mco_user,
  $mco_password,
  $mco_connector,

  $puppet_master_hostname,

  $exclude_network = $admin_network,
  $exclude_cidr = $admin_network_cidr,

  $keystone_host = '127.0.0.1',
  $keystone_nailgun_user = 'nailgun',
  $keystone_nailgun_pass = 'nailgun',

  $dns_domain,
  ) {

  file { [$confdir,"$confdir/nailgun"]:
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => 0755,
  }
  $fuel_key = $::generate_fuel_key

  file { "${confdir}/nailgun/settings.yaml":
    content => template("nailgun/settings.yaml.erb"),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => File["/etc/nailgun"],
  }

}
