notice('MODULAR: virtual_ips.pp')

$internal_int                = hiera('internal_int')
$public_int                  = hiera('public_int',  undef)
$primary_controller_nodes    = hiera('primary_controller_nodes', false)
$network_scheme              = hiera('network_scheme', {})
$vip_management_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
$vip_public_cidr_netmask     = netmask_to_cidr($primary_controller_nodes[0]['public_netmask'])
$use_neutron                 = hiera('use_neutron', false)

#todo:(sv): temporary commented. Will be uncommented while
#           'multiple-l2-network' feature re-implemented
# if $use_neutron {
#   ip_mgmt_other_nets = join($network_scheme['endpoints']["$internal_int"]['other_nets'], ' ')
# }

$vips = { # Do not convert to ARRAY, It can't work in 2.7
    management   => {
      namespace            => 'haproxy',
      nic                  => $internal_int,
      base_veth            => "${internal_int}-hapr",
      ns_veth              => "hapr-m",
      ip                   => hiera('management_vip'),
      cidr_netmask         => $vip_management_cidr_netmask,
      gateway              => 'none',
      gateway_metric       => '0',
      bridge               => $network_scheme['roles']['management'],
      other_networks       => $vip_mgmt_other_nets,
      with_ping            => false,
      ping_host_list       => "",
    },
    management_vrouter => {
      namespace            => 'vrouter',
      nic                  => $internal_int,
      base_veth            => "${internal_int}-vrouter",
      ns                   => 'vrouter',
      ns_veth              => 'vr-mgmt',
      ip                   => hiera('management_vrouter_vip'),
      cidr_netmask         => $vip_management_cidr_netmask,
      gateway              => 'none',
      gateway_metric       => '0',
      bridge               => $network_scheme['roles']['management'],
      tie_with_ping        => false,
      ping_host_list       => "",
    },
}

if $public_int {
  #todo:(sv): temporary commented. Will be uncommented while
  #           'multiple-l2-network' feature re-implemented
  # if $use_neutron{
  #   vip_publ_other_nets = join($network_scheme['endpoints']["$public_int"]['other_nets'], ' ')
  # }

    $vips[public] = {
      namespace            => 'haproxy',
      nic                  => $public_int,
      base_veth            => "${public_int}-hapr",
      ns_veth              => 'hapr-p',
      ip                   => hiera('public_vip'),
      cidr_netmask         => $vip_public_cidr_netmask,
      gateway              => $network_scheme['endpoints']['br-ex']['gateway'],
      gateway_metric       => '10',
      bridge               => $network_scheme['roles']['ex'],
      other_networks       => $vip_publ_other_nets,
      tie_with_ping        => hiera('run_ping_checker', true),
      ping_host_list       => $network_scheme['endpoints']['br-ex']['gateway'],
    }
    $vips[public_vrouter] = {
      namespace               => 'vrouter',
      nic                     => $public_int,
      base_veth               => "${public_int}-vrouter",
      ns_veth                 => 'vr-ex',
      ns                      => 'vrouter',
      ip                      => hiera('public_vrouter_vip'),
      cidr_netmask            => $vip_public_cidr_netmask,
      gateway                 => $network_scheme['endpoints']['br-ex']['gateway'],
      gateway_metric          => '0',
      bridge                  => $network_scheme['roles']['ex'],
      ns_iptables_start_rules => "iptables -t nat -A POSTROUTING -o vr-ex -j MASQUERADE",
      ns_iptables_stop_rules  => "iptables -t nat -D POSTROUTING -o vr-ex -j MASQUERADE",
      collocation             => 'management_vrouter',
    }
  }
$vip_keys = keys($vips)

class virtual_ips () {
  file { 'ns-ipaddr2-ocf':
    path   =>'/usr/lib/ocf/resource.d/fuel/ns_IPaddr2',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ocf/ns_IPaddr2',
  }

  cluster::virtual_ips { $::vip_keys:
    vips => $::vips,
  }

  # Some topologies might need to keep the vips on the same node during
  # deploymenet. This would only need to be changed by hand.
  $keep_vips_together = false
  if ($keep_vips_together) {
    cs_rsc_colocation { 'ha_vips':
      ensure      => present,
      primitives  => [prefix(keys($::vips),"vip__")],
      after       => Cluster::Virtual_ips[$::vip_keys]
    }
  } # End If keep_vips_together
}

case $operatingsystem {
  Centos: { $conntrackd_package = "conntrack-tools" }
  Ubuntu: { $conntrackd_package = "conntrackd" }
}

class { 'virtual_ips': }

if $use_conntrackd {
  package { $conntrackd_package:
    ensure  => installed,
    require => Class['virtual_ips'],
  } ->

  file { '/etc/conntrackd/conntrackd.conf':
    content => template('cluster/conntrackd.conf.erb'),
  }

  cs_resource {'conntrackd':
    ensure          => present,
    primitive_class => 'ocf',
    provided_by     => 'fuel',
    primitive_type  => 'ns_conntrackd',
    metadata                 => {
      'migration-threshold' => 'INFINITY',
      'failure-timeout'     => '180s'
    },
    complex_type => 'master',
    ms_metadata => {
      'notify'      => 'true',
      'ordered'     => 'false',
      'interleave'  => 'true',
      'clone-node-max' => '1',
      'master-max'  => '1',
      'master-node-max' => '1',
      'target-role' => 'Master'
    },
    operations => {
      'monitor' => {
      'interval' => '30',
      'timeout'  => '60'
    },
    'monitor:Master' => {
      'role' => 'Master',
      'interval' => '27',
      'timeout'  => '60'
      },
    },
  }

  cs_colocation { 'conntrackd-with-public-vip':
    primitives => [ 'conntrackd:Master', 'vip__public_vrouter' ],
  }

  File['/etc/conntrackd/conntrackd.conf'] -> Cs_resource['conntrackd'] -> Service['conntrackd']

  service { 'conntrackd':
    ensure   => 'running',
    enable   => true,
    provider => 'pacemaker',
  }
}

