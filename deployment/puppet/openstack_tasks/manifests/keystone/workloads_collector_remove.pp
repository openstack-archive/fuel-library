class openstack_tasks::keystone::workloads_collector_remove {

  notice('MODULAR: keystone/workloads_collector_remove.pp')

  $workloads_hash   = hiera_hash('workloads_collector', {})
  $workloads_username = $workloads_hash['username']
  $workloads_tenant   = $workloads_hash['tenant']

  class { '::osnailyfacter::wait_for_keystone_backends':}

  Class['::osnailyfacter::wait_for_keystone_backends'] -> Keystone_user_role <||>
  Class['::osnailyfacter::wait_for_keystone_backends'] -> Keystone_user <||>

  keystone_user_role { "${workloads_username}@${workloads_tenant}" :
    ensure => 'absent',
  } ->

  keystone_user { $workloads_username:
    ensure => 'absent',
  }

}
