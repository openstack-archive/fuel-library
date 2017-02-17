class provision::dhcpd (
  $network_address    = $::provision::params::network_address,
  $network_mask       = $::provision::params::network_mask,
  $broadcast_address  = $::provision::params::broadcast_address,
  $start_address      = $::provision::params::start_address,
  $end_address        = $::provision::params::end_address,
  $router             = $::provision::params::router,
  $next_server        = $::provision::params::next_server,
  $dns_address        = $::provision::params::dns_address,
  $domain_name        = $::provision::params::domain_name,
  $ddns_key           = $::provision::params::ddns_key,
  $ddns_key_algorithm = $::provision::params::ddns_key_algorithm,
  $ddns_key_name      = $::provision::params::ddns_key_name,
  $known_hosts        = [],
) inherits provision::params {

  package { "dhcpd" :
    name => $::provision::params::dhcpd_package,
  }

  file { $::provision::params::dhcpd_conf :
    ensure  => present,
    content => template('provision/dhcpd.conf.erb'),
    owner   => 'dhcpd',
    group   => 'dhcpd',
    mode    => '0640',
    require => Package["dhcpd"],
    notify  => Service["dhcpd"],
  }

  file { $::provision::params::dhcpd_conf_d :
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    require => Package["dhcpd"],
  }

  # It is just a file that could be modified by other modules
  file { $::provision::params::dhcpd_conf_extra :
    ensure => present,
    require => File[$::provision::params::dhcpd_conf_d],
  }

  service { "dhcpd" :
    name => $::provision::params::dhcpd_service,
    ensure  => running,
    enable  => true,
    hasrestart => false,
    hasstatus => false,
    require => Package["dhcpd"],
  }

}
