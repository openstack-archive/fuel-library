class puppet::agent_config(
  $pluginsync     = true,
  $puppet_confdir = '/etc/puppet',
  $server,
) {

  Ini_setting {
    ensure  => present,
    section => 'agent',
    path    => "${puppet_confdir}/puppet.conf",
  }

  ini_setting {'pluginsync':
    setting => 'pluginsync',
    value   => $pluginsync,
  }
  
  ini_setting {'server':
    setting => 'server',
    value   => $server,
  }

}
  