require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/netconfig.pp'
describe manifest do
  shared_examples 'catalog' do

    network_metadata = task.hiera_hash 'network_metadata'
    network_scheme   = task.hiera_hash 'network_scheme'
    use_neutron      = task.hiera 'use_neutron'
    default_gateway  = task.hiera 'default_gateway'
    set_xps          = task.hiera 'set_xps', true
    set_rps          = task.hiera 'set_rps', true

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
    end
    if set_xps
      it { should contain_sysfs_config_value('xps_cpus').with(
        'ensure'  => 'present',
        'name'    => '/etc/sysfs.d/xps_cpus.conf',
        'sysfs'   => '/sys/class/net/*/queues/tx-*/xps_cpus',
        'exclude' => '/sys/class/net/lo/*',
      )}
    end
  end

  test_ubuntu_and_centos manifest
end

