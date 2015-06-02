notice('MODULAR: keystone/workloads_collector.pp')

$workloads_hash = hiera('workloads_collector', {})

$workloads_username = $workloads_hash['username']
$workloads_tenant = $workloads_hash['tenant']

keystone_user_role { "$workloads_username@$workloads_tenant":
  ensure => absent,
} ->

keystone_user { $workloads_username:
  ensure => absent,
}
