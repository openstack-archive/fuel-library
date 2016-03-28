# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/netconfig.pp'
describe manifest do
  shared_examples 'catalog' do

    network_metadata = Noop.hiera_hash 'network_metadata'
    network_scheme   = Noop.hiera_hash 'network_scheme'
    use_neutron      = Noop.hiera 'use_neutron'
    default_gateway  = Noop.hiera 'default_gateway'
    set_xps          = Noop.hiera 'set_xps', true
    set_rps          = Noop.hiera 'set_rps', true
    dpdk_config      = Noop.hiera_hash 'dpdk', {}
    enable_dpdk      = dpdk_config.fetch 'enabled', false

    it { should contain_class('l23network').with('use_ovs' => use_neutron) }
    it { should contain_sysctl__value('net.ipv4.conf.all.arp_accept').with('value' => '1') }
    it { should contain_sysctl__value('net.ipv4.conf.default.arp_accept').with('value' => '1') }
    it { should contain_class('openstack::keepalive').with(
       'tcpka_time'   => '30',
       'tcpka_probes' => '8',
       'tcpka_intvl'  => '3',
       'tcp_retries2' => '5',
    ) }
    it { should contain_sysctl__value('net.core.netdev_max_backlog').with('value' => '261144') }
    it { should contain_class('sysfs') }
    it { should contain_ping_host(default_gateway.join()).with('ensure' => 'up') }
    it { should contain_exec('wait-for-interfaces').with(
      'path'    => '/usr/bin:/bin',
      'command' => 'sleep 32',
    )}
    it { should contain_exec('wait-for-interfaces').that_requires('Class[l23network]') }
    if set_rps
      it { should contain_sysfs_config_value('rps_cpus').with(
        'ensure'  => 'present',
        'name'    => '/etc/sysfs.d/rps_cpus.conf',
        'sysfs'   => '/sys/class/net/*/queues/rx-*/rps_cpus',
        'exclude' => '/sys/class/net/lo/*',

      )}
    else
      it { should contain_sysfs_config_value('rps_cpus').with(
        'ensure'  => 'absent',
        'name'    => '/etc/sysfs.d/rps_cpus.conf',
      )}
    end
    if set_xps
      it { should contain_sysfs_config_value('xps_cpus').with(
        'ensure'  => 'present',
        'name'    => '/etc/sysfs.d/xps_cpus.conf',
        'sysfs'   => '/sys/class/net/*/queues/tx-*/xps_cpus',
        'exclude' => '/sys/class/net/lo/*',
      )}
    else
      it { should contain_sysfs_config_value('xps_cpus').with(
        'ensure'  => 'absent',
        'name'    => '/etc/sysfs.d/xps_cpus.conf',
      )}
    end
    if enable_dpdk
      it 'should set dpdk-specific options for OVS' do
        should contain_class('l23network::l2::dpdk').with('use_dpdk' => true)
      end
    else
      it 'should skip dpdk-specific options for OVS' do
        should contain_class('l23network::l2::dpdk').with('use_dpdk' => false)
      end
    end
  end

  test_ubuntu_and_centos manifest
end

