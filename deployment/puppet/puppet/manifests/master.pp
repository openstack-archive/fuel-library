class puppet::master (
    $puppet_master_ports = $puppet::params::puppet_master_ports,
    $puppet_master_version = $puppet::params::puppet_master_version,
    $puppet_service_name = "puppetmaster"
  ) inherits puppet::params {
  
  include puppet::service

  package { $puppet::params::puppet_master_packages :
    ensure => $puppet_master_version,
  }
   
  file { "/etc/puppet/puppet.conf":
    content => template($puppet::params::puppet_config_template),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package[$puppet::params::puppet_master_packages],
    notify => Service["puppetmaster"],
  }->
  
  class {"puppet::master_config":
    require => Package[$puppet::params::puppet_master_packages],
    notify => Service["puppetmaster"],
  }
  
}
