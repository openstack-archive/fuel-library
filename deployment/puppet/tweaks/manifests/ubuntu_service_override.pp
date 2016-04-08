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
define tweaks::ubuntu_service_override (
  $service_name = $name,
  $package_name = $name,
) {
  if $::operatingsystem == 'Ubuntu' {
    if ! is_pkg_installed($package_name) {
      # https://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt
      # use policy-rc.d to really ensure services don't get started on
      # installation as service override files are only used if a job
      # configuration file exists (see man 5 init)
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

      ensure_resource('file', "${service_name}.override")
        path    => "/etc/init/${service_name}.override",
        content => 'manual',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
      }

      File["${service_name}.override"] ->
        File['create-policy-rc.d'] ->
          Package <| name == $package_name |> ->
            Exec['remove-policy-rc.d']
      File['create-policy-rc.d'] ->
        Package <| title == $package_name |> ->
          Exec['remove-policy-rc.d']
      Exec['remove-policy-rc.d'] ->
        Service <| name == $service_name |>
      Exec['remove-policy-rc.d'] ->
        Service <| title == $service_name |>
    }
  }
}
