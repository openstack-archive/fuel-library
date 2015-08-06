# Tweak Service httpd or apache2
class tweaks::apache_wrappers (
  $timeout = '60',
) {

  $service_name = $::osfamily ? {
    'RedHat' => 'httpd',
    'Debian' => 'apache2',
    default  => fail("Unsupported osfamily: ${::osfamily}"),
  }

  $debug_args = "2>&1 | logger -t 'apacheinit'  -p 'daemon.info'"
  $start_command = "service ${service_name} start ${debug_args}|| sleep ${timeout} && service ${service_name} start ${debug_args}"
  $stop_command  = "service ${service_name} stop ${debug_args}|| sleep ${timeout} && service ${service_name} stop ${debug_args}"

  disable_garbage_collector()

  Service <| name == $service_name or title == $service_name |> {
    start      => $start_command,
    stop       => $stop_command,
    hasrestart => false,
  }
}
