class puppet::master (
    $puppet_master_ports = $puppet::params::puppet_master_ports,
    $puppet_master_version = $puppet::params::puppet_master_version,
  ) inherits puppet::params {

  package { $puppet::params::puppet_master_packages :
    ensure => $puppet_master_version,
  }
   
  package {  $puppet::params::mongrel_packages: ensure=>"installed"}
  
  class {"puppet::master_config":
    require => Package[$puppet::params::puppet_master_packages],
    notify => Service["puppet"],
  }
  
  file { $puppet::params::daemon_config_file:
    content => template($puppet::params::daemon_config_template),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package[$puppet::params::puppet_master_packages],
    notify => Service["puppet"],
  }

  service { "puppet":
    enable => true,
    ensure => "running",
    require => [
                Package[$puppet::params::puppet_master_packages],
                Package[ $puppet::params::mongrel_packages],
                ],
  }
}
