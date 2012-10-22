class puppet::master (
  $puppet_package_version = $puppet::params::puppet_master_version,
  $puppet_master_ports = "18140 18141 18142 18143",
  $plugin_sync = true
  ) inherits puppet::params {

  package { $puppet::params::puppet_master_packages :
    ensure => $puppet_package_version,
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
