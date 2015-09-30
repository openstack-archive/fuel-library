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
  $monitor_ensure   = present,
) {

  # NOTE: We do not use a clone resource here as disks may be different per host
  cs_resource { "sysinfo_${::fqdn}":
    ensure          => $monitor_ensure,
    primitive_class => 'ocf',
    provided_by     => 'pacemaker',
    primitive_type  => 'SysInfo',
    parameters      => {
      'disks'         => join(any2array($disks), ' '),
      'min_disk_free' => $min_disk_free,
      'disk_unit'     => $disk_unit,
    },
    operations      => { 'monitor' => { 'interval' => $monitor_interval } },
  }

  # Have service migrate if health turns red from the failed disk check
  cs_property { 'node-health-strategy':
    ensure   => present,
    value    => 'migrate-on-red',
    provider => 'crm',
  }

  cs_rsc_location { "sysinfo-on-${::fqdn}":
    primitive  => "sysinfo_${::fqdn}",
    node_name  => $::fqdn,
    node_score => 'INFINITY',
    cib        => "sysinfo_${::fqdn}",
  }
}
