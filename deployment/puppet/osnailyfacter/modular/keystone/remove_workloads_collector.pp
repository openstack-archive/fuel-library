notice('MODULAR: keystone/workloads_collector_remove.pp')

$workloads_hash   = hiera('workloads_collector', {})
$service_endpoint = hiera('service_endpoint')

$haproxy_stats_url  = "http://${service_endpoint}:10000/;csv"
$workloads_username = $workloads_hash['username']
$workloads_tenant   = $workloads_hash['tenant']

haproxy_backend_status { 'keystone-admin' :
  name  => 'keystone-2',
  count => '200',
  step  => '6',
  url   => $haproxy_stats_url,
} ->

keystone_user_role { "$workloads_username@$workloads_tenant" :
  ensure => 'absent',
} ->

keystone_user { $workloads_username:
  ensure => 'absent',
}
