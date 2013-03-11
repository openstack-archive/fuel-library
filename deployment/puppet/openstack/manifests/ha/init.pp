
class openstack::corosync (
  bind_address = '127.0.0.1',
  multicast_address = '239.1.1.2',
  secauth = 'off',
)
{

}

#Define shadow CIB

Cs_resource {cib => 'shadow'}
Cs_property {cib => 'shadow'}
Cs_order {cib => 'shadow'}
Cs_colocation {cib => 'shadow'}
Cs_group {cib => 'shadow'}

Class['corosync']->Cs_shadow['shadow']->Cs_property['expected-quorum-votes']->
Cs_property['no-quorum-policy']->Cs_property['stonith-enabled']->Cs_resource<||>



file {'quantum-dhcp-agent':
  path=>'/usr/lib/ocf/resource.d/pacemaker/quantum-dhcp-agent', 
  mode => 644,
  require =>Package['pacemaker'],
  owner => root,
  group => root,
  source => "puppet:///modules/openstack/quantum-dhcp-agent",
  before => Service['pacemaker']
} 
file {'quantum-l3-agent':
  path=>'/usr/lib/ocf/resource.d/pacemaker/quantum-l3-agent', 
  mode => 644,
  require =>Package['pacemaker'],
  owner => root,
  group => root,
  source => "puppet:///modules/openstack/quantum-l3-agent",
  before => Service['pacemaker']
} 
file {'quantum-ovs-agent':
  path=>'/usr/lib/ocf/resource.d/pacemaker/quantum-ovs-agent', 
  mode => 644,
  require =>Package['pacemaker'],
  owner => root,
  group => root,
  source => "puppet:///modules/openstack/quantum-ovs-agent",
  before => Service['pacemaker']
} 



corosync::service { 'pacemaker':
  version => '0',
  notify  => Service['corosync'],
}
class { 'corosync':
  enable_secauth    => $secauth,
  bind_address      => $bind_address,
  multicast_address => $multicast_address
}

anchor {'corosync_pre':}

cs_shadow {'shadow': cib=>'shadow'}
cs_property { 'expected-quorum-votes':
  ensure => present,
  cib => 'shadow',
  value  => $number
}
cs_property { 'no-quorum-policy':
  ensure => present,
  cib => 'shadow',
  value  => $quorum_policy,
}
cs_property { 'stonith-enabled':
  cib => 'shadow',
  ensure => present,
  value  => $stonith,
}
cs_property { 'placement-strategy':
  cib => 'shadow',
  ensure => absent,
  value  => 'default',
}
cs_resource { 'quantum-dhcp-agent':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'quantum-dhcp-agent',
  parameters => {},
  operations      => {
    'monitor'  => {
      'interval' => '20'
    }
  },
}
cs_resource { 'quantum-l3-agent':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'quantum-l3-agent',
  parameters => {},
  operations      => {
    'monitor'  => {
      'interval' => '20'
    }
  },
}
cs_resource { 'quantum-ovs-agent':
  ensure          => present,
  primitive_class => 'ocf',
  provided_by     => 'pacemaker',
  primitive_type  => 'quantum-ovs-agent',
  parameters => {},
  operations      => {
    'monitor'  => {
      'interval' => '20'
    }
  },
}
anchor {'corosync_post':}
}
