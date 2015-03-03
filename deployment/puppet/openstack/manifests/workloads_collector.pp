# == Class: openstack::workloads_collector
#
# Creates a keystone user to connect workload statistics
# from a running OpenStack environment.
#
# === Parameters
#
# [*workloads_password*]
#   (required) Password.
# [*enabled*]
#   (optional) Creates the user. Defaults to true.
# [*workloads_user*]
#   (optional) Defaults to 'workloads_collector'.
# [*tenant*]
#   (optional) Defaults to 'services'.
#
class openstack::workloads_collector(
  $workloads_password = false,
  $enabled            = true,
  $workloads_username = 'workloads_collector',
  $workloads_tenant   = 'services',
) {

  validate_string($workloads_password)

  keystone_user { $workloads_username:
    ensure          => present,
    password        => $workloads_password,
    enabled         => $enabled,
    tenant          => $workloads_tenant,
  }

  keystone_user_role { "$workloads_username@$workloads_tenant":
    ensure => present,
    roles  => ['admin'],
  }
}
