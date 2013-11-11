class puppet::agent_config(
 $pluginsync     = true,
  $puppet_confdir = '/etc/puppet',
  $autosign = true,
  $server = undef
)  {

  Ini_setting {
    ensure  => present,
    section => 'agent',
    path    => "${puppet_confdir}/puppet.conf",
  }
  
  if ($server) {
    ini_setting {'agent_server':
      setting => 'server',
      value   => $server,
    }
  }
  
  ini_setting {'agent_pluginsync':
    setting => 'pluginsync',
    value   => $pluginsync,
  }
  

}
  