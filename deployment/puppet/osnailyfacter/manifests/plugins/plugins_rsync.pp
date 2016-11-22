class osnailyfacter::plugins::plugins_rsync {

  notice('MODULAR: plugins/plugins_rsync.pp')

  exec { 'run-plugins-pull' :
    command   => '/usr/bin/plugins-pull',
    logoutput => 'on_failure',
    tries     => '3',
    try_sleep => '3',
    timeout   => '600',
    require   => File['plugins-pull'],
  }

}
