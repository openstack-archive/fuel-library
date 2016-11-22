class osnailyfacter::plugins::plugins_rsync {

  notice('MODULAR: plugins/plugins_rsync.pp')

  $plugins_pull_path = '/usr/local/bin/plugins-pull'

  file { 'plugins-pull' :
    ensure => 'present',
    path   => $plugins_pull_path,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/osnailyfacter/plugins-pull.rb',
  }

  exec { 'run-plugins-pull' :
    command   => $plugins_pull_path,
    logoutput => 'on_failure',
    tries     => '3',
    try_sleep => '3',
    timeout   => '600',
    require   => File['plugins-pull'],
  }

}
