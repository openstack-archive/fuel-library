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
#   (optional) Is user enabled. Defaults to true.
# [*workloads_user*]
#   (optional) Defaults to 'fuel_stats_user'.
# [*tenant*]
#   (optional) Defaults to 'services'.
# [*create_user*]
#   (optional) Is creation of user required. Defaults to false.
#
class openstack::workloads_collector(
  $workloads_password = false,
  $enabled            = true,
  $workloads_username = 'fuel_stats_user',
  $workloads_tenant   = 'services',
  $workloads_create_user = false
) {

  if $workloads_create_user {

    validate_string($workloads_password)

    keystone_user { $workloads_username:
      ensure          => present,
      password        => $workloads_password,
      enabled         => $enabled,
    }

    keystone_tenant { $workloads_tenant:
      ensure => present,
    }

    keystone_user_role { "$workloads_username@$workloads_tenant":
      ensure => present,
      roles  => ['admin'],
    }
  }
}
