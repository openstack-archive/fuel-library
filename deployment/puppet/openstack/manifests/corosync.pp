
class openstack::corosync (
  $bind_address = '127.0.0.1',
  $multicast_address = '239.1.1.2',
  $secauth = 'off',
  $stonith = 'false',
  $quorum_policy = 'ignore',
  $expected_quorum_votes = "2",
  $unicast_addresses = undef
) {

#Define shadow CIB

#Cs_resource {cib => 'shadow'}
#Cs_property {cib => 'shadow'}
#Cs_order {cib => 'shadow'}
#Cs_colocation {cib => 'shadow'}
#Cs_group {cib => 'shadow'}

Class['::corosync']->Cs_shadow<||>
Class['::corosync']->Cs_property<||>->Cs_resource<||>
Cs_property<||>->Cs_shadow<||>
Cs_property['no-quorum-policy']->Cs_property['stonith-enabled']->Cs_property['start-failure-is-fatal']

file {'filter_quantum_ports.py':
  path=>'/usr/bin/filter_quantum_ports.py', 
  mode => 744,
  require =>[Package['corosync'],File['/root/openrc']],
  owner => root,
  group => root,
  source => "puppet:///modules/openstack/filter_quantum_ports.py",
} 
File['filter_quantum_ports.py'] -> File<| title == 'quantum-agent-dhcp' |>
File['filter_quantum_ports.py'] -> File<| title == 'quantum-l3-agent' |>
File['filter_quantum_ports.py'] -> File<| title == 'quantum-ovs-agent' |>
file {'quantum-agent-dhcp':
  path=>'/usr/lib/ocf/resource.d/pacemaker/quantum-agent-dhcp', 
  mode => 744,
  require =>Package['corosync'],
  owner => root,
  group => root,
  source => "puppet:///modules/openstack/quantum-agent-dhcp",
  before => Service['corosync']
} 
file {'quantum-l3-agent':
  path=>'/usr/lib/ocf/resource.d/pacemaker/quantum-agent-l3', 
  mode => 744,
  require =>Package['pacemaker'],
  owner => root,
  group => root,
  source => "puppet:///modules/openstack/quantum-agent-l3",
  before => Service['corosync']
} 
file {'quantum-ovs-agent':
  path=>'/usr/lib/ocf/resource.d/pacemaker/quantum-agent-ovs', 
  mode => 744,
  require =>Package['pacemaker'],
  owner => root,
  group => root,
  source => "puppet:///modules/openstack/quantum-agent-ovs",
  before => Service['corosync']
} 

corosync::service { 'pacemaker':
  version => '0',
  notify  => Service['corosync'],
}
class { '::corosync':
  enable_secauth    => $secauth,
  bind_address      => $bind_address,
  multicast_address => $multicast_address,
  unicast_addresses => $unicast_addresses
}



anchor {'corosync_pre':}

#cs_property { 'expected-quorum-votes':
#  ensure => present,
#  cib => 'shadow',
#  value  => $expected_quorum_votes
#}
cs_property { 'no-quorum-policy':
  ensure => present,
# cib => 'properties',
  value  => $quorum_policy,
  retries => 5
}
cs_property { 'stonith-enabled':
#  cib => 'properties',
  ensure => present,
  value  => $stonith,
}
cs_property { 'start-failure-is-fatal':
#  cib => 'properties',
  ensure => present,
  value  => "false",
}
#
#cs_property { 'placement-strategy':
#  cib => 'shadow',
#  ensure => absent,
#  value  => 'default',
#}


anchor {'corosync_post':}
}
