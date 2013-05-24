  class { "puppet" :  }
  
#  class { "puppet::storedb" :
#    puppet_stored_dbname => "puppet",
#    puppet_stored_dbuser => "puppet",
#    puppet_stored_dbpassword => "Johmek0mi9WeGhieshiFiB9rizai0M",
#    puppet_stored_dbsocket => "/var/lib/mysql/mysql.sock",
#    mysql_root_password => "eo6raesh7aThe5ahbahgohphupahk5",
#  }

  class {puppet::thin: }
  
  class { "puppet::nginx":
    puppet_master_hostname => "product-centos.localdomain",
  }
  
  class { "puppet::agent_config":
    server => "product-centos.localdomain"
  }
