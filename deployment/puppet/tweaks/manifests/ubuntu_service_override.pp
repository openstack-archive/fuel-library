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
      if $::service_provider == 'systemd' {
        # Use 'systemd' mask / unmask to disable service actions
        $systemd_service_file = "/etc/systemd/system/${service_name}.service"

        ensure_resources(
          'exec',
          {
            'systemctl-daemon-reload-on-disable' => {},
            'systemctl-daemon-reload-on-enable'  => {}
          },
          {
            path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
            command => 'systemctl daemon-reload',
          }
        )

        ensure_resource('file', "create-override-${service_name}", {
          ensure => link,
          backup => '.bak',
          path   => $systemd_service_file,
          target => '/dev/null',
        })

        ensure_resource('exec', "remove-override-${service_name}", {
          path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
          command => "mv -f ${systemd_service_file}.bak ${systemd_service_file} || rm -f ${systemd_service_file}",
          onlyif  => "test $(readlink -nf ${systemd_service_file}) = /dev/null",
        })

        File["create-override-${service_name}"] ->
          Exec['systemctl-daemon-reload-on-disable'] ->
            Exec["remove-override-${service_name}"] ->
              Exec['systemctl-daemon-reload-on-enable']

        File["create-override-${service_name}"] ->
          Package <| name == $package_name |> { provider =>  'apt_fuel' } ->
            Exec['systemctl-daemon-reload-on-disable']
        File["create-override-${service_name}"] ->
          Package <| title == $package_name |> { provider => 'apt_fuel' } ->
            Exec['systemctl-daemon-reload-on-disable']

        Exec['systemctl-daemon-reload-on-enable'] ->
          Service <| name == $service_name |>
        Exec['systemctl-daemon-reload-on-enable'] ->
          Service <| title == $service_name |>
      } else {
        # Use 'sysvinit' policy-rc.d mechanism.
        # This will not work with upstart if using commands like 'service xxx start'
        # It was here before so using it as a kind of default.

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
}