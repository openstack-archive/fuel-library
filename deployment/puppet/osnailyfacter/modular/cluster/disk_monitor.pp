notice('MODULAR: cluster/disk_checks.pp')

if !(hiera('role') in hiera('corosync_roles')) {
    fail('The node role is not in corosync roles')
}

$primary_controller = hiera('primary_controller')
$disks              = hiera('corosync_disk_monitor', ['/var/log', '/var/lib/glance', '/var/libmysql'])
$min_disk_free      = hiera('corosync_min_disk_space', '100M')
$disk_unit          = hiera('corosync_disk_unit', 'M')
$monitor_interval   = hiera('corosync_disk_monitor_interval', '15s')

class { 'cluster::sysinfo':
  primary_controller => $primary_controller,
  disks              => $disks,
  min_disk_free      => $min_disk_free,
  disk_unit          => $disk_unit,
  monitor_interval   => $monitor_interval,
}
