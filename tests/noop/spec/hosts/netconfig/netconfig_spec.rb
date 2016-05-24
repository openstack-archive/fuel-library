# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
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
    mgmt_vrouter_vip = Noop.hiera 'management_vrouter_vip'
    roles            = Noop.hiera 'roles', []
    mongo_roles      = ['primary-mongo', 'mongo']

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

    not_in_group_with_vip = network_scheme['endpoints']['br-mgmt']['IP'].find{
      |ipnet| IPAddr.new(ipnet).include?(IPAddr.new(mgmt_vrouter_vip))}.nil?

    if network_scheme['endpoints'].has_key?('br-ex')
      it { should contain_l23network__l3__ifconfig('br-ex').with(
        'gateway' => network_scheme['endpoints']['br-ex']['gateway']
      )}
    elsif !(roles & mongo_roles).empty?
      it { should contain_l23network__l3__ifconfig('br-fw-admin').with(
        'gateway' => network_scheme['endpoints']['br-fw-admin']['gateway']
      )}
    elsif !not_in_group_with_vip
      it { should contain_l23network__l3__ifconfig('br-mgmt').with(
        'gateway' => mgmt_vrouter_vip
      )}
    else
      it { should contain_l23network__l3__ifconfig('br-fw-admin').with(
        'gateway' => network_scheme['endpoints']['br-fw-admin']['gateway']
      )}
    end
  end

  test_ubuntu_and_centos manifest
end

