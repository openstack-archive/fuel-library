notice('MODULAR: puppetsync.pp')

Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

$fuel_settings = parseyaml($astute_settings_yaml)

class { 'fuel::puppetsync':
  bind_address => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
}

fuel::systemd {['rsyncd']:
  start         => true,
  template_path => 'fuel/systemd/restart_template.erb',
  config_name   => 'restart.conf',
  require       => Class['fuel::puppetsync'],
}
