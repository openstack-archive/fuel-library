class puppet::fileserver_config(
  $puppet_confdir = '/etc/puppet/',
  $autosign = true,
  $section     = "ssh_keys",
  $path = '/var/lib/puppet/ssh_keys',
  $allow = '*',
  $deny = undef,
  $notify_service = "thin" 
){
  
  if (! defined(Service[$notify_service])) {
    service {$notify_service:}
  }

  Ini_setting {
    ensure  => present,
    section => section,
    path    => "${puppet_confdir}/fileserver.conf",
    notify => $notify_service, 
  }
  
  ini_setting {'path':
    setting => 'path',
    value   => $path,
    notify => $notify_service,
  }
  
  ini_setting {'allow':
    setting => 'allow',
    value   => $allow,
    notify => $notify_service,
  }
  
  if ($deny) {  
	  ini_setting {'deny':
	    setting => 'deny',
	    value   => $deny,
	    notify => $notify_service,
	  }
	}

}
  