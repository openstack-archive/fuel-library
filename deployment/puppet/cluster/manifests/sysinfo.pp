# == Class: cluster::sysinfo
#
# Configure pacemaker sysinfo disk monitor
#
# === Parameters
#
# [*primary_controller*]
#  (required) Boolean to indicate if this is the primary controller or not. The
#  resources only get defined on the primary controller for the cluster but the
#  location is defined on any node on this cluster that this should run on.
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
  $primary_controller,
  $disks            = [],
  $min_disk_free    = '100M',
  $disk_unit        = 'M',
  $monitor_interval = '15s',
  $monitor_ensure   = present,
) {

  if $primary_controller {
    cs_resource { 'sysinfo':
      ensure          => $monitor_ensure,
      primitive_class => 'ocf',
      provided_by     => 'pacemaker',
      primitive_type  => 'SysInfo',
      complex_type    => 'clone',
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
  }

  cs_rsc_location { "clone_sysinfo-on-${::fqdn}":
    primitive  => 'sysinfo',
    node_name  => $::fqdn,
    node_score => 'INFINITY',
    cib        => 'clone_sysinfo',
  }
}
