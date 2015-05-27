class tweaks::apache_wrappers {
  $init_dir = '/etc/init.d'

  if $::osfamily == 'RedHat' {
    $service_name = 'httpd'
  } elsif $::osfamily == 'Debian' {
    $service_name = 'apache2'
  } else {
    fail("OS '${::operatingsystem}' is not supported!")
  }

  $init_script = "${init_dir}/${service_name}"

  $start_command = "${init_script} start || sleep 60 && ${init_script} start"
  $stop_command  = "${init_script} stop || sleep 60 && ${init_script} stop"

  disable_garbage_collector()

  Service <| name == $service_name or title == $service_name |> {
    start      => $start_command,
    stop       => $stop_command,
    hasrestart => false,
  }
}
