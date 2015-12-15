define tweaks::ubuntu_service_override (
  $service_name = $name,
  $package_name = $name,
) {
  if $::operatingsystem == 'Ubuntu' {
    $override_file = "/etc/init/${service_name}.override"
    $file_name     = "create_${service_name}_override"
    $exec_name     = "remove_${service_name}_override"

    if get_pkg_state($package_name) != 'installed' {
      file { $file_name :
        ensure  => present,
        path    => $override_file,
        content => 'manual',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
      }

      exec { $exec_name :
        path    => [ '/sbin', '/bin', '/usr/bin', '/usr/sbin' ],
        command => "rm -f ${override_file}",
        onlyif  => "test -f ${override_file}",
      }

      File[$file_name] -> Package <| name == $package_name |> -> Exec[$exec_name]
      File[$file_name] -> Package <| title == $package_name |> -> Exec[$exec_name]
      Exec[$exec_name] -> Service <| name == $service_name |>
      Exec[$exec_name] -> Service <| title == $service_name |>
    }
  }
}
