class puppet::service ($enable_service = false) inherits puppet::params
{
  if ($enable_service) {
  	service { "puppetmaster":
	      enable => true,
	      ensure =>"running",
	      require => [
	                  Package[$puppet::params::puppet_master_packages],
	                  Class["puppet::master_config"]
	                  ],
	  }
	}
	
	else {
    service { "puppetmaster":
        enable => false,
        ensure =>"stopped",
        require => [
                    Package[$puppet::params::puppet_master_packages],
                    Class["puppet::master_config"]
                    ],
    }
    
  }
	  
}