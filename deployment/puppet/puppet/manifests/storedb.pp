class puppet::storedb (
  $puppet_stored_dbname,
  $puppet_stored_dbuser,
  $puppet_stored_dbpassword,
  $puppet_stored_dbsocket,
  $mysql_root_password,
  
) inherits puppet::params {
  
  package { $puppet::params::mysql_packages : ensure=> "installed"}

  # http://projects.puppetlabs.com/issues/9290
  package { "rails":
    provider => "gem",
    ensure => "3.0.10",
  }

  package { "activerecord":
    provider => "gem",
    ensure => "3.0.10",
  }

  case $::osfamily {
    'RedHat': {
       package { "mysql":
          provider => "gem", 
          ensure => "2.8.1",
       }
       
    }
  }
  
  class { "puppet::mysql":
    puppet_stored_dbname => $puppet_stored_dbname,
    puppet_stored_dbuser => $puppet_stored_dbuser,
    puppet_stored_dbpassword => $puppet_stored_dbpassword,
    mysql_root_password => $mysql_root_password,
  }
 
  
  file { "/etc/puppet/puppet.conf":
    content => template("puppet/puppet.conf.erb"),
    owner   => "puppet",
    group   => "puppet",
    mode    => 0600,
    require => Package[$puppet::params::puppet_master_packages],
    notify  => Service["puppetmaster_service"],
  }

}
