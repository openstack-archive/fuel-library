class osnailyfacter::upgrade::pkg_upgrade {
  $packages_to_upgrade = hiera_hash('upgrade_packages', get_packages_for_upgrade('/etc/fuel/maintenance/apt/sources.list.d/'))

  create_resources('package', $packages_to_upgrade)

  $corosync_roles   = hiera('corosync_roles', ['primary-controller', 'controller'])
  $corosync_upgrade = has_key($packages_to_upgrade, 'corosync') or has_key($packages_to_upgrade, 'pacemaker')
  if roles_include($corosync_roles) and $corosync_upgrade {
    $content_policy = "#!/bin/bash\n[[ \"\$1\" == \"pacemaker\" ]] && exit 101\n"
    $policyrc_file  = '/usr/sbin/policy-rc.d'

    ensure_resource('file', 'create-policy-rc.d', {
      ensure  => present,
      path    => $policyrc_file,
      content => $content_policy,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
    })

    exec { 'remove_policy':
      command => "rm -rf ${policyrc_file}",
      path    => '/bin',
    }

    ensure_resource('service', 'pacemaker', { ensure  => running })

    File['create-policy-rc.d'] ->
      Package<| title == 'corosync' or title == 'pacemaker' |> ->
        Exec['remove_policy'] ->
          Service['pacemaker']
  }
}
