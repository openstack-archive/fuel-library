class osnailyfacter::netconfig::netconfig {

  notice('MODULAR: netconfig/netconfig.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  prepare_network_config($network_scheme)

  $dpdk_options = hiera_hash('dpdk', {})

  if ($::l23_os =~ /(?i:redhat7|centos7)/) {
    # do not install
    $ovs_datapath_package_name = false
  } elsif $::l23_os =~ /(?i:centos6)/ and $::kernelmajversion == '3.10' {
    # install more specific version for Centos6 AND 3.10 kernel
    $ovs_datapath_package_name = 'kmod-openvswitch-lt'
  } else {
    # do not change default behavior
    $ovs_datapath_package_name = undef
  }

  class { '::l23network' :
    use_ovs                   => hiera('use_ovs', false),
    ovs_datapath_package_name => $ovs_datapath_package_name,
    use_dpdk                  => pick($dpdk_options['enabled'], false),
    dpdk_options              => $dpdk_options,
  }
  $sdn = generate_network_config()
  notify {'SDN': message => $sdn }

  #Set arp_accept to 1 by default #lp1456272
  sysctl::value { 'net.ipv4.conf.all.arp_accept':   value => '1'  }
  sysctl::value { 'net.ipv4.conf.default.arp_accept':   value => '1'  }

  ### TCP connections keepalives and failover related parameters ###
  # configure TCP keepalive for host OS.
  # Send 3 probes each 8 seconds, if the connection was idle
  # for a 30 seconds. Consider it dead, if there was no responces
  # during the check time frame, i.e. 30+3*8=54 seconds overall.
  # (note: overall check time frame should be lower then
  # nova_report_interval).
  class { '::openstack::keepalive' :
    tcpka_time   => '30',
    tcpka_probes => '8',
    tcpka_intvl  => '3',
    tcp_retries2 => '7',
  }

  # increase network backlog for performance on fast networks
  sysctl::value { 'net.core.netdev_max_backlog':   value => '261144' }

  L2_port<||> -> Sysfs_config_value<||>
  L3_ifconfig<||> -> Sysfs_config_value<||>
  L3_route<||> -> Sysfs_config_value<||>

  class { '::sysfs' :}

  if hiera('set_rps', true) {
    sysfs_config_value { 'rps_cpus' :
      ensure  => 'present',
      name    => '/etc/sysfs.d/rps_cpus.conf',
      value   => cpu_affinity_hex($::processorcount),
      sysfs   => '/sys/class/net/*/queues/rx-*/rps_cpus',
      exclude => '/sys/class/net/lo/*',
      }
  } else {
    sysfs_config_value { 'rps_cpus' :
      ensure => 'absent',
      name   => '/etc/sysfs.d/rps_cpus.conf',
    }
  }

  if hiera('set_xps', true) {
    sysfs_config_value { 'xps_cpus' :
      ensure  => 'present',
      name    => '/etc/sysfs.d/xps_cpus.conf',
      value   => cpu_affinity_hex($::processorcount),
      sysfs   => '/sys/class/net/*/queues/tx-*/xps_cpus',
      exclude => '/sys/class/net/lo/*',
    }
  } else {
    sysfs_config_value { 'xps_cpus' :
      ensure => 'absent',
      name   => '/etc/sysfs.d/xps_cpus.conf',
    }
  }

  if !defined(Package['irqbalance']) {
    package { 'irqbalance':
      ensure => installed,
    }
  }

  if !defined(Service['irqbalance']) {
    service { 'irqbalance':
      ensure  => running,
      require => Package['irqbalance'],
    }
  }

  # We need to wait at least 30 seconds for the bridges and other interfaces to
  # come up after being created.  This should allow for all interfaces to be up
  # and ready for traffic before proceeding with further deploy steps. LP#1458954
  exec { 'wait-for-interfaces':
    path    => '/usr/bin:/bin',
    command => 'sleep 32',
  }

  Class['::l23network'] ->
  Exec['wait-for-interfaces']

}
