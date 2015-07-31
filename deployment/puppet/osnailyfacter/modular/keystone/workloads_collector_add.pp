notice('MODULAR: keystone/workloads_collector_add.pp')

$workloads_hash   = hiera('workloads_collector', {})
$service_endpoint = hiera('service_endpoint')

$haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

haproxy_backend_status { 'keystone-admin' :
  name  => 'keystone-2',
  count => '200',
  step  => '6',
  url   => $haproxy_stats_url,
} ->

class { 'openstack::workloads_collector':
  enabled               => $workloads_hash['enabled'],
  workloads_username    => $workloads_hash['username'],
  workloads_password    => $workloads_hash['password'],
  workloads_tenant      => $workloads_hash['tenant'],
  workloads_create_user => true,
}
