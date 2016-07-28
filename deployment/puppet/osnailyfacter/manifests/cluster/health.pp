class osnailyfacter::cluster::health {

  notice('MODULAR: cluster/health.pp')

  unless (roles_include(hiera('corosync_roles')) or tags_include(hiera('corosync_tags'))) {
    fail('The node roles/tags is not in corosync roles/tags')
  }

  # load the mounted filesystems from our custom fact and remove not needed
  $mount_points = delete($::mounts, ['/boot', '/var/lib/horizon'])

  $disks            = hiera('corosync_disks', $mount_points)
  $min_disk_free    = hiera('corosync_min_disk_space', '512M')
  $disk_unit        = hiera('corosync_disk_unit', 'M')
  $monitor_interval = hiera('corosync_disk_monitor_interval', '15s')

  class { '::cluster::sysinfo':
    disks            => $disks,
    min_disk_free    => $min_disk_free,
    disk_unit        => $disk_unit,
    monitor_interval => $monitor_interval,
  }

}
