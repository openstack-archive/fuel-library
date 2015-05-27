class tweaks::apache_wrappers {
  $init_dir = '/etc/init.d'
  $sleep_time = '5'
  $retry_count = '10'

  if $::osfamily == 'RedHat' {
    $service_name = 'httpd'
  } elsif $::osfamily == 'Debian' {
    $service_name = 'apache2'
  } else {
    fail("OS '${::operatingsystem}' is not supported!")
  }

  $init_script = "${init_dir}/${service_name}"
  $start_command = "n='0'; while :; do '${init_script} start'; test \"$?\" -eq '0' && break; let 'n += 1'; test \"\$n\" -ge '${retry_count}' && break; sleep '${sleep_time}'; done"
  $stop_command = "n='0'; while :; do '${init_script} stop'; test \"$?\" -eq '0' && break; let 'n += 1'; test \"\$n\" -ge '${retry_count}' && break; sleep '${sleep_time}'; done"
  $restart_command = "n='0'; while :; do '${init_script} restart'; test \"$?\" -eq '0' && break; let 'n += 1'; test \"\$n\" -ge '${retry_count}' && break; sleep '${sleep_time}'; done"

  Service <| name == $service_name or title == $service_name |> {
    start    => $start_command,
    stop     => $stop_command,
    restart  => $restart_command,
  }
}
