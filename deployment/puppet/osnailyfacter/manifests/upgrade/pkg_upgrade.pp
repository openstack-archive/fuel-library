class osnailyfacter::upgrade::pkg_upgrade {
  # hardcode with retries and sleeps for resolving lock issue
  # should be rewritten
  exec { 'do_upgrade':
    command   => 'apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"',
    environment => [ 'DEBIAN_FRONTEND=noninteractive' ],
    path      => ['/usr/bin', '/usr/local/sbin', '/usr/sbin', '/sbin', '/bin' ],
    timeout   => 1700,
    try_sleep => 10,
    tries     => 5,
    logoutput => true,
  }
  if roles_include(['controller', 'primary-controller']) {
    $content_policy = "#!/bin/bash\n[[ \"\$1\" == \"pacemaker\" ]] && exit 101\n"
    $policyrc_file  = '/usr/sbin/policy-rc.d'

    ensure_resource('file', 'create-policy-rc.d', {
      ensure  => present,
      path    => $policyrc_file,
      content => $content_policy,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      before  => Exec['do_upgrade']
    })

    exec { 'remove_policy':
      command => "rm -rf ${policyrc_file}",
      path    => '/bin'
      require => Exec['do_upgrade'],
    }

    ensure_resource('service', 'pacemaker', {
      ensure  => running,
      require => Exec['remove_policy']
    })
  }
}
