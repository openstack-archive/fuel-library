node default {
  
  class { "puppetmaster" :  }
  
  class { "puppetmaster::storedb" :
    puppet_stored_dbname => "puppet",
    puppet_stored_dbuser => "puppet",
    puppet_stored_dbpassword => "Johmek0mi9WeGhieshiFiB9rizai0M",
    puppet_stored_dbsocket => "/var/lib/mysql/mysql.sock",
    mysql_root_password => "eo6raesh7aThe5ahbahgohphupahk5",
  }
  
  class { "puppetmaster::nginx":
    puppet_master_hostname => "product-centos.mirantis.com",
    cacert => "/var/lib/puppet/ssl/certs/hostname.pem",
    cakey => "/var/lib/puppet/ssl/private_keys/hostname.pem",
  }
  
  class { "puppetmaster::client_config":
    puppet_master_hostname => "product-centos.mirantis.com"
  }
}
