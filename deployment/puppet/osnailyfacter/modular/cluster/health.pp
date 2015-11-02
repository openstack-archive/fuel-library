notice('MODULAR: cluster/health.pp')

if !(hiera('role') in hiera('corosync_roles')) {
    fail('The node role is not in corosync roles')
}

# load the mounted filesystems from our custom fact, remove boot
$mount_points = delete(split($::mounts, ','), '/boot')

$disks              = hiera('corosync_disks', $mount_points)
$min_disk_free      = hiera('corosync_min_disk_space', '512M')
$disk_unit          = hiera('corosync_disk_unit', 'M')
$monitor_interval   = hiera('corosync_disk_monitor_interval', '15s')

class { 'cluster::sysinfo':
  disks              => $disks,
  min_disk_free      => $min_disk_free,
  disk_unit          => $disk_unit,
  monitor_interval   => $monitor_interval,
}
