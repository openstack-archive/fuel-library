node default {
  
  class { "puppet" :  }
  
  class { "puppet::storedb" :
    puppet_stored_dbname => "puppet",
    puppet_stored_dbuser => "puppet",
    puppet_stored_dbpassword => "Johmek0mi9WeGhieshiFiB9rizai0M",
    puppet_stored_dbsocket => "/var/lib/mysql/mysql.sock",
    mysql_root_password => "eo6raesh7aThe5ahbahgohphupahk5",
  }
  
  class { "puppet::nginx":
    puppet_master_hostname => "product-centos.mirantis.com",
    hostcert => "/var/lib/puppet/ssl/certs/hostname.pem",
    hostprivkey => "/var/lib/puppet/ssl/private_keys/hostname.pem",
  }
  
  class { "puppet::agent_config":
    server => "product-centos.mirantis.com"
  }
}
