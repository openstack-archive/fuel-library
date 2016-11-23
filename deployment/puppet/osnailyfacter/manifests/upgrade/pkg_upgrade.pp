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

    Package<| title == 'corosync' |> ->
      Service['corosync'] -> 
        File['create-policy-rc.d'] ->
          Package<| title == 'pacemaker' |> ->
            Exec['remove_policy'] ->
              Service['pacemaker']
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
      # Swift services restart isn't required.

      $swift_partition = hiera('swift_partition', '/var/lib/glance/node')

      if $swift_partition =~ /\/var\/lib\/glance\// {
        # We can't use 'file' resource because we need to be sure that swift user and
        # group exist. They could be absent in case of adding new controller node
        # for already upgraded environment.
        exec { '/var/lib/glance/':
          command   => 'chgrp swift /var/lib/glance/',
          onlyif    => 'getent group swift && test -d /var/lib/glance/',
          path      => ['/bin/', '/usr/bin/'],
          logoutput => 'on_failure',
        } ->
        exec { $swift_partition:
          command   => "chown -R swift:swift ${swift_partition}",
          onlyif    => "getent passwd swift && test -d ${swift_partition}",
          path      => ['/bin/', '/usr/bin/'],
          logoutput => 'on_failure',
        }
      }
    }
  }
}
