notice('MODULAR: keystone/workloads_collector.pp')

$workloads_hash        = hiera('workloads_collector', {})

class { 'openstack::workloads_collector':
  enabled              => $workloads_hash['enabled'],
  workloads_username   => $workloads_hash['username'],
  workloads_password   => $workloads_hash['password'],
  workloads_tenant     => $workloads_hash['tenant'],
}
