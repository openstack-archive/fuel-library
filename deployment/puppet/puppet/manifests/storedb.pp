class puppetmaster::storedb (
  $puppet_stored_dbname,
  $puppet_stored_dbuser,
  $puppet_stored_dbpassword,
  $puppet_stored_dbsocket,
  $mysql_root_password,
  
) inherits puppetmaster::params{
  
  class { "puppetmaster::mysql":
    puppet_stored_dbname => $puppet_stored_dbname,
    puppet_stored_dbuser => $puppet_stored_dbuser,
    puppet_stored_dbpassword => $puppet_stored_dbpassword,
    mysql_root_password => $mysql_root_password,
  }

  class { "puppetmaster::packages" : }
  
  file { "/etc/puppet/puppet.conf":
    content => template("puppetmaster/puppet.conf.erb"),
    owner   => "puppet",
    group   => "puppet",
    mode    => 0600,
    require => Package[$puppetmaster::params::puppet_master_packages],
    notify  => Service["puppetmaster"],
  }

}
