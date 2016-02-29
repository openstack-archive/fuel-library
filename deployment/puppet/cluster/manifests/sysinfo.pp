# == Class: cluster::sysinfo
#
# Configure pacemaker sysinfo disk monitor
#
# === Parameters
#
# [*disks*]
#  (optional) array of mount points to monitor for free space. / is monitored
#  by default it does not need to be specified.
#  Defaults to []
#
# [*min_disk_free*]
#  (optional) Minimum amount of free space required for the paritions
#  Defaults to '100M'
#
# [*disk_unit*]
#  (optional) Unit for disk space
#  Defaults to 'M'
#
# [*monitor_interval*]
#  (optional) Internval to monitor free space
#  Defaults to '60s'
#
# [*monitor_ensure*]
#  (optional) Ensure the corosync monitor is installed
#  Defaults to present
#
class cluster::sysinfo (
  $disks            = [],
  $min_disk_free    = '100M',
  $disk_unit        = 'M',
  $monitor_interval = '15s',
  $monitor_ensure   = 'present',
) {

  pcmk_resource { "sysinfo_${::fqdn}" :
    ensure                 => $monitor_ensure,
    primitive_class        => 'ocf',
    primitive_provider     => 'pacemaker',
    primitive_type         => 'SysInfo',
    parameters             => {
      'disks'         => join(any2array($disks), ' '),
      'min_disk_free' => $min_disk_free,
      'disk_unit'     => $disk_unit,
    },
    operations             => { 'monitor' => { 'interval' => $monitor_interval } },
  }

  # Have service migrate if health turns red from the failed disk check
  pcmk_property { 'node-health-strategy':
    ensure   => $monitor_ensure,
    value    => 'migrate-on-red',
  }

  pcmk_location { "sysinfo-on-${::fqdn}":
    ensure    => $monitor_ensure,
    primitive => "sysinfo_${::fqdn}",
    node      => $::fqdn,
    score     => 'INFINITY',
  }
}
