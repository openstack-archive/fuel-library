class osnailyfacter::upgrade::pkg_upgrade {

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

  # hardcode with retries and sleeps for resolving lock issue
  # should be rewritten
  exec { 'do_upgrade':
    command   => 'DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"',
    path      => '/usr/bin',
    timeout   => '1700',
    try_sleep => '10',
    tries     => '5',
    before    => File['remove_policy']
  }

  file { 'remove_policy':
    ensure => absent,
    path   => $policyrc_file,
  }

  if roles_include(['controller', 'primary-controller']) {
    ensure_resource('service', 'pacemaker', {
      ensure  => running,
      require => File['remove_policy']
    })
  }
}
