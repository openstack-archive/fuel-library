class puppet::service ($puppet_service_name = "puppetmaster")
inherits puppet::params 
{
	service { "puppetmaster":
	    name => $puppet_service_name,
	    enable => true,
	    ensure =>"running",
	    require => [
	                Package[$puppet::params::puppet_master_packages],
	                Class["puppet::master_config"]
	                ],
	}
	
	exec {"puppetmaster_stopped":
	  command => "/etc/init.d/puppetmaster stop",
	  require => Package[$puppet::params::puppet_master_packages]
	}
}