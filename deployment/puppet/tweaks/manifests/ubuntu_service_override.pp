# == Type: tweaks::ubuntu_service_override
#
#  Disable services from starting when the package is installed on Ubuntu OS
#
# == Parameters
#
# [*service_name*]
#  The name of the service that is associated with the package being installed.
#  Defaults to $name
#
# [*package_name*]
#  The name of the package that is being installed that has a service to be
#  prevented from being started as part of the installation process.
#  Defaults to $name
#
# [*mask_service*]
#  Boolean variable to mask service.
#  Defaults to false
#
define tweaks::ubuntu_service_override (
  $service_name = $name,
  $package_name = $name,
  $mask_service = false,
) {
  if $::operatingsystem == 'Ubuntu' {
    if ! is_pkg_installed($package_name) {
      # https://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt
      # use policy-rc.d to really ensure services don't get started on
      # installation as service override files are only used if a job
      # configuration file exists (see man 5 init)
      $systemd_unit = "/etc/systemd/system/${service_name}.service"

      if $::service_provider != 'systemd' {
        ensure_resource('file', $systemd_unit, {
          ensure  => 'absent',
        })
      } elsif $mask_service {
        ensure_resource('file', $systemd_unit, {
          ensure => 'symlink',
          target => '/dev/null'
        })
      }

      Service <| title == $service_name |> ->
      File <| title == $systemd_unit |>

      $policyrc_file = '/usr/sbin/policy-rc.d'
      # use ensure resource as we only want a single instance of the
      # policy-rc.d file in the catalog
      ensure_resource('file', 'create-policy-rc.d', {
        ensure  => present,
        path    => $policyrc_file,
        content => "#!/bin/bash\nexit 101",
        mode    => '0755',
        owner   => 'root',
        group   => 'root'
      })
      # use ensure resource as we only want a single remove exec in the catalog
      ensure_resource('exec', 'remove-policy-rc.d', {
        path    => [ '/sbin', '/bin', '/usr/bin', '/usr/sbin' ],
        command => "rm -f ${policyrc_file}",
        onlyif  => "test -f ${policyrc_file}",
      })

      File['create-policy-rc.d'] ->
        Package <| name == $package_name |> { provider =>  'apt_fuel' } ->
          Exec['remove-policy-rc.d']
      File['create-policy-rc.d'] ->
        Package <| title == $package_name |> { provider => 'apt_fuel' } ->
          Exec['remove-policy-rc.d']
      Exec['remove-policy-rc.d'] ->
        Service <| name == $service_name |>
      Exec['remove-policy-rc.d'] ->
        Service <| title == $service_name |>
    }
  }
}
