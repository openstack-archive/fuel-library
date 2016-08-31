class osnailyfacter::upgrade::pkg_upgrade {
  # hardcode with retries and sleeps for resolving lock issue
  # should be rewritten
  exec { 'do_upgrade':
    command     => 'apt-get dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"',
    environment => [ 'DEBIAN_FRONTEND=noninteractive' ],
    path        => ['/usr/bin', '/usr/local/sbin', '/usr/sbin', '/sbin', '/bin' ],
    timeout     => 1700,
    try_sleep   => 10,
    tries       => 5,
    logoutput   => true,
  }

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
      before  => Exec['do_upgrade']
    })

    exec { 'remove_policy':
      command => "rm -rf ${policyrc_file}",
      path    => '/bin',
      require => Exec['do_upgrade'],
    }

    ensure_resource('service', 'pacemaker', {
      ensure  => running,
      require => Exec['remove_policy']
    })
  }

  if roles_include(['controller', 'primary-controller']) {
    $storage_hash = hiera_hash('storage', {})
    if (!$storage_hash['images_ceph'] and !$storage_hash['objects_ceph'] and !$storage_hash['images_vcenter']) {
      # Glance package update changes permissions for /var/lib/glance and makes
      # it and its subdirectories owned by glance:glance (it executes in postinst stage).
      # We use /var/lib/glance/node as swift storage, and we need to allow
      # swift user to write into this directory. We should update all subdirectories
      # in /var/lib/glance/node to be owned by swift:swift. This should be applied right
      # after glance package update to decrease swift service downtime to minimum.

      exec { 'fix_permissions':
        command   => '/bin/chown -R swift:swift /var/lib/glance/node/',
        onlyif    => '/usr/bin/test -d /var/lib/glance/node/',
        logoutput => true,
      }
    }
  }
}
