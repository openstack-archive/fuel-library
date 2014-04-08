class puppet::thin (
  $port = 18140,
  $servers = 4,
  $sockets = false, #not implemented  
) inherits puppet::params {
  
  $thin_daemon_config_template = "puppet/init_puppetmaster_thin.erb"
  $role_name="puppetmasterd"
  $rack_config = "/usr/share/puppet/ext/rack/files/config.ru"

  package { $puppet::params::thin_packages:
          ensure => installed;
  }

  exec { "thin_install":
      command => "/usr/bin/thin install",
      require => [
                  Package[$puppet::params::thin_packages],
                  ],
      
  }->
  exec {"thin_config_directory":
    command => '/bin/ln -s /etc/thin1.8 /etc/thin',
    creates => '/etc/thin',
    before => Exec["thin_configure"] 
  }
  
#  if ! defined([Package[$puppet::params::puppet_master_packages]]) {
#      package { $puppet::params::puppet_master_packages :
#         ensure => present,
#      }
#  }
  
  exec { "thin_configure":
      #command => "thin config --config /etc/thin/puppet.yaml -P /var/run/puppet/${role_name}.pid -e production --servers 4 --daemonize --socket /var/run/puppet/${rolename}.sock --chdir /etc/puppet/ -R ${rack_config}",
      command => "/usr/bin/thin config --config /etc/thin/puppet.yaml -P /var/run/puppet/${role_name}.pid -e production --servers ${servers} --daemonize --port ${port} --chdir /etc/puppet/  -R ${rack_config}",
      require => [Package[$puppet::params::thin_packages],
                  Exec["thin_install"],
                  Package[$puppet::params::puppet_master_packages],
                 ],
      notify => Service["thin"],
  }

# Force puppet master to generate certificates 
  exec {"start-puppet-master":
      command => "/etc/init.d/puppetmaster start",
      require => Service["puppetmaster"]
      
  }->
  exec {"stop-puppet-master":
      command => "/etc/init.d/puppetmaster stop",
      before => Service["thin"],
  }
    

  service { "thin":
      name => "thin",
      enable => true,
      ensure =>"running",
      require => [
                  Package[$puppet::params::thin_packages],
                  ],
  }

}