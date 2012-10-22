class puppet::storedb (
  $puppet_stored_dbname,
  $puppet_stored_dbuser,
  $puppet_stored_dbpassword,
  $puppet_stored_dbsocket,
  $mysql_root_password,
  
) inherits puppet::params{
  
  class { "puppet::mysql":
    puppet_stored_dbname => $puppet_stored_dbname,
    puppet_stored_dbuser => $puppet_stored_dbuser,
    puppet_stored_dbpassword => $puppet_stored_dbpassword,
    mysql_root_password => $mysql_root_password,
  }

  class { "puppet::packages" : }
  
  file { "/etc/puppet/puppet.conf":
    content => template("puppet/puppet.conf.erb"),
    owner   => "puppet",
    group   => "puppet",
    mode    => 0600,
    require => Package[$puppet::params::puppet_master_packages],
    notify  => Service["puppet"],
  }

}
