# Configures monit watchdog for given process name.
#
# [matching] - Match process by string. Optional. Default the same as process name.
# [pidfile]  - Match process by its pidfile. Optional. Default ''.
# [stop_command] - How monit should issue stop command for process. Mandatory.
# [start_command] - How monit should issue start command for process. Mandatory.
# [timeout] - Configure monit to wait for the start/stop action to finish by checking the
#   process table. Optional. Default 30 sec.
#
# Note, if service is already defined in catalog, it would be redefined to monit provider.
#
define monit::process(
  $matching = $name,
  $ensure   = 'running',
  $pidfile  = '',
  $timeout  = 30,
  $start_command,
  $stop_command
) {

  include monit
  $included = $::monit::params::included

  file { "${included}/${name}" :
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => template('monit/process.erb'),
    notify  => Class['monit::service'],
    require => Class['monit::package'],
  }

  if defined(Service[$name]) {
    Service <| title == $name |> {
      ensure   => $ensure,
      provider => 'monit',
      require  => [ Service['monit'], File["${included}/${name}"], ],
    }
  } else {
    service {$name:
      ensure   => $ensure,
      provider => 'monit',
      require  => [ Service['monit'], File["${included}/${name}"], ],
    }
  }

}
