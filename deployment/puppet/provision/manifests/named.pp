class provision::named (
  $domain_name        = $::provision::params::domain_name,
  $dns_address        = $::provision::params::dns_address,
  $forwarders         = $::provision::params::forwarders,
  $ddns_key           = $::provision::params::ddns_key,
  $ddns_key_algorithm = $::provision::params::ddns_key_algorithm,
  $ddns_key_name      = $::provision::params::ddns_key_name,
) inherits provision::params {

  package { "named" :
    name => $::provision::params::named_package,
  }

  file { "/var/named" :
    ensure => directory,
    owner => 'named',
    group => 'named',
    mode => '0750',
    require => Package["named"],
  }

  file { $::provision::params::named_conf :
    ensure  => present,
    content => template('provision/named.conf.erb'),
    owner   => 'named',
    group   => 'named',
    mode    => '0640',
    require => Package["named"],
    notify  => Service["named"],
  }

  file { ["/var/named/${domain_name}", "/var/named/${reverse_zone}"] :
    ensure  => present,
    content => template('provision/zone.erb'),
    owner   => 'named',
    group   => 'named',
    mode    => '0644',
    require => Package["named"],
    notify  => Service["named"],
  }

  service { "named" :
    name    => $::provision::params::named_service,
    ensure  => running,
    enable  => true,
    hasrestart => false,
    hasstatus => false,
    require => Package["named"],
  }

}
