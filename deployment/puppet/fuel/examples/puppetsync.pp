notice('MODULAR: puppetsync.pp')

Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

$fuel_settings = parseyaml($astute_settings_yaml)

class { "fuel::puppetsync": }

fuel::systemd {['rsyncd']:
  start => true,
  template_path => 'fuel/systemd/restart_template.erb',
  config_name => 'restart.conf',
  require => Class["fuel::puppetsync"],
}
