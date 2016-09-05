# Update packages (Ubuntu case)
class osnailyfacter::upgrade::pkg_upgrade {

  osnailyfacter::upgrade::pkgs{'do_upgrade':  }

  $corosync_roles = hiera('corosync_roles', ['primary-controller', 'controller'])
  if roles_include($corosync_roles) {
    $content_policy = "#!/bin/bash\n[[ \"\$1\" == \"pacemaker\" ]] && exit 101\n"
    $policyrc_file  = '/usr/sbin/policy-rc.d'

    ensure_resource('file', 'create-policy-rc.d', {
      ensure  => present,
      path    => $policyrc_file,
      content => $content_policy,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      before  => Osnailyfacter::Upgrade::Pkgs['do_upgrade'],
    })

    exec { 'remove_policy':
      command => "rm -rf ${policyrc_file}",
      path    => '/bin',
      require => Osnailyfacter::Upgrade::Pkgs['do_upgrade'],
    }

    ensure_resource('service', 'pacemaker', {
      ensure  => running,
      require => Exec['remove_policy']
    })
  }
}
