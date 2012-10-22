class puppet::packages {
  
  
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
  
}  

