notice('MODULAR: keystone/workloads_collector_remove.pp')

$workloads_username = $workloads_hash['username']
$workloads_tenant   = $workloads_hash['tenant']

class {'::osnailyfacter::wait_for_keystone_backends':} ->

keystone_user_role { "$workloads_username@$workloads_tenant" :
  ensure => 'absent',
} ->

keystone_user { $workloads_username:
  ensure => 'absent',
}
