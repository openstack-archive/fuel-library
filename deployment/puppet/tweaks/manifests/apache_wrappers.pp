# Tweak Service httpd or apache2
class tweaks::apache_wrappers (
  $timeout = '60',
) {

  $service_name = $::osfamily ? {
    'RedHat' => 'httpd',
    'Debian' => 'apache2',
    default  => fail("Unsupported osfamily: ${::osfamily}"),
  }

  $start_command = "service ${service_name} start || sleep ${timeout} && service ${service_name} start"
  $stop_command  = "service ${service_name} stop || sleep ${timeout} && service ${service_name} stop"

  disable_garbage_collector()

  Service <| name == $service_name or title == $service_name |> {
    start      => $start_command,
    stop       => $stop_command,
    hasrestart => false,
  }
}
