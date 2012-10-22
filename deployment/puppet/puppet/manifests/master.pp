class puppetmaster::master (
  $puppet_package_version = $puppetmaster::params::puppet_master_version,
  $puppet_master_ports = "18140 18141 18142 18143",
  $plugin_sync = true
  ) inherits puppetmaster::params {

  package { $puppetmaster::params::puppet_master_packages :
    ensure => $puppet_package_version,
  }
   
  package {  $puppetmaster::params::mongrel_packages: ensure=>"installed"}
  
  class {"puppetmaster::master_config":
    require => Package[$puppetmaster::params::puppet_master_packages],
    notify => Service["puppetmaster"],
  }
  
  file { $puppetmaster::params::daemon_config_file:
    content => template($puppetmaster::params::daemon_config_template),
    owner => 'root',
    group => 'root',
    mode => 0644,
    require => Package[$puppetmaster::params::puppet_master_packages],
    notify => Service["puppetmaster"],
  }

  service { "puppetmaster":
    enable => true,
    ensure => "running",
    require => [
                Package[$puppetmaster::params::puppet_master_packages],
                Package[ $puppetmaster::params::mongrel_packages],
                ],
  }

  }
