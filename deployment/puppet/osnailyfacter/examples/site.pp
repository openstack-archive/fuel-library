$openstack_version = {
  'keystone'   => 'latest',
  'glance'     => 'latest',
  'horizon'    => 'latest',
  'nova'       => 'latest',
  'novncproxy' => 'latest',
  'cinder'     => 'latest',
}

tag("${deployment_id}::${::environment}")

#Stages configuration
stage {'first': } ->
stage {'openstack-custom-repo': } ->
stage {'netconfig': } ->
stage {'corosync_setup': } ->
stage {'cluster_head': } ->
stage {'openstack-firewall': } -> Stage['main']

stage {'glance-image':
  require => Stage['main'],
}

###
$default_gateway = '10.0.204.1'
$dns_nameservers = ['10.0.204.1','8.8.8.8']
$internal_netmask = '255.255.255.0'
$public_netmask = '255.255.255.0'

parsejson($::network_data)


class node_netconfig (
  $mgmt_ipaddr,
  $mgmt_netmask  = '255.255.255.0',
  $public_ipaddr = undef,
  $public_netmask= '255.255.255.0',
  $save_default_gateway=false,
  $quantum = $quantum,
  $default_gateway
) {
  if $quantum {
    l23network::l3::create_br_iface {'mgmt':
      interface => $internal_interface, # !!! NO $internal_int /sv !!!
      bridge    => $internal_br,
      ipaddr    => $mgmt_ipaddr,
      netmask   => $mgmt_netmask,
      dns_nameservers      => $dns_nameservers,
      save_default_gateway => $save_default_gateway,
    } ->
    l23network::l3::create_br_iface {'ex':
      interface => $public_interface, # !! NO $public_int /sv !!!
      bridge    => $public_br,
      ipaddr    => $public_ipaddr,
      netmask   => $public_netmask,
      gateway   => $default_gateway,
    }
  } else {
    # nova-network mode
    l23network::l3::ifconfig {$public_int:
      ipaddr  => $public_ipaddr,
      netmask => $public_netmask,
      gateway => $default_gateway,
    }
    l23network::l3::ifconfig {$internal_int:
      ipaddr  => $mgmt_ipaddr,
      netmask => $mgmt_netmask,
      dns_nameservers      => $dns_nameservers,
    }
  }
  l23network::l3::ifconfig {$private_interface: ipaddr=>'none' }
}


class os_common {
  if $deployment_source == 'cli'
  { 
     class {'l23network': use_ovs=>$quantum, stage=> 'netconfig'}  
      class {'::node_netconfig':
      mgmt_ipaddr    => $::internal_address,
      mgmt_netmask   => $::internal_netmask,
      public_ipaddr  => $::public_address,
      public_netmask => $::public_netmask,
      stage          => 'netconfig',
  }
  }
  else
  {
    class {'osnailyfacter::network_setup': stage => 'netconfig'}
  }
  class {'openstack::firewall': stage => 'openstack-firewall'}

  # Workaround for fuel bug with firewall
  firewall {'003 remote rabbitmq ':
    sport   => [ 4369, 5672, 41055, 55672, 61613 ],
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall'],
  }
}
node default {
  case $deployment_mode {
    "singlenode": { 
      include osnailyfacter::cluster_simple 
      class {'os_common':}
      }
    "multinode": { 
      include osnailyfacter::cluster_simple
      class {'os_common':}
      }
    "ha": { 
      include osnailyfacter::cluster_ha
      class {'os_common':}
      }
    "rpmcache": { include osnailyfacter::rpmcache }
  }

}
