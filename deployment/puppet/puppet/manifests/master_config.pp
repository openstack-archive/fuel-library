class puppet::master_config(
  $pluginsync     = true,
  $puppet_confdir = '/etc/puppet',
  $autosign = true,
) {

  Ini_setting {
    ensure  => present,
    section => 'master',
    path    => "${puppet_confdir}/puppet.conf",
  }

  ini_setting {'pluginsync':
    setting => 'pluginsync',
    value   => $pluginsync,
  }
  
  ini_setting {'autosign':
    setting => 'autosign',
    value   => $autosign,
  }
  
  ini_setting {'certname':
    setting => 'certname',
    value   => $::hostname,
  }
  
  

}
  