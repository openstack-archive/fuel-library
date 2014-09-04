require 'spec_helper'

describe 'neutron::agents::n1kv_vem' do

  let :facts do
    { :osfamily => 'RedHat' }
  end

  it 'should have a n1kv-vem config file' do
    should contain_file('/etc/n1kv/n1kv.conf').with(
      :ensure  => 'present',
      :owner   => 'root',
      :group   => 'root',
      :mode    => '0664'
    )
  end

  it 'install n1kv-vem' do
    should contain_package('libnl').with_before('Package[nexus1000v]')
    should contain_package('openvswitch').with_before('Package[nexus1000v]')
    should contain_package('nexus1000v').with_notify('Service[nexus1000v]')
    should contain_service('nexus1000v').with_ensure('running')
  end

  context 'with local file vem rpm' do
    let :params do
      {
        :n1kv_source => 'vem.rpm'
      }
    end

    it 'verify dependency' do
      should contain_package('nexus1000v').with_source('/var/n1kv/vem.rpm')
      should contain_file('/var/n1kv/vem.rpm').that_requires('File[/var/n1kv]')
      should contain_file('/var/n1kv/vem.rpm').with(
        :owner   => 'root',
        :group   => 'root',
        :mode    => '0664'
      )
    end
  end

  context 'remote vem rpm' do
    let :params do
    {
      :n1kv_source => 'http://www.cisco.com/repo'
    }
    end

    it 'verify dependency' do
      should contain_package('nexus1000v').without_source
      should contain_yumrepo('cisco-vem-repo').with(
        :baseurl  => 'http://www.cisco.com/repo',
        :enabled => 1
      )
    end
  end

  it 'execute reread config upon config change' do
    should contain_exec('vemcmd reread config') \
      .that_subscribes_to('File[/etc/n1kv/n1kv.conf]')
  end

  context 'verify n1kv.conf default' do
    let :params do
    {
      :n1kv_vsm_ip        => '9.0.0.1',
      :n1kv_vsm_domain_id => 900,
      :host_mgmt_intf     => 'eth9'
    }
    end
    it do
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^l3control-ipaddr 9.0.0.1/)
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^switch-domain 900/)
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^host-mgmt-intf eth9/)
      should contain_file('/etc/n1kv/n1kv.conf') \
        .without_content(/^phys/)
      should contain_file('/etc/n1kv/n1kv.conf') \
        .without_content(/^virt/)
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^node-type compute/)
    end
  end

  context 'verify node_type' do
    let :params do
    {
      :node_type        => 'network',
    }
    end
    it do
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^node-type network/)
      should contain_file('/etc/n1kv/n1kv.conf') \
        .without_content(/^node-type compute/)
    end
  end

  context 'verify n1kv.conf with uplinks' do
    let :params do
    {
      :uplink_profile => { 'eth1' => 'prof1',
                           'eth2' => 'prof2'
                         }
    }
    end
    it do
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^phys eth1 profile prof1/)
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^phys eth2 profile prof2/)
    end

  end

  context 'verify n1kv.conf with vtep info' do
    let :params do
    {
      :vtep_config => { 'vtep1' => { 'profile' => 'profint',
                                     'ipmode'  => 'dhcp'
                                   },
                        'vtep2' => { 'profile'   => 'profint',
                                     'ipmode'    => 'static',
                                     'ipaddress' => '192.168.1.1',
                                     'netmask'   => '255.255.255.0'
                                   }
                      }
    }
    end
    it do
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^virt vtep1 profile profint mode dhcp/)
      should contain_file('/etc/n1kv/n1kv.conf') \
        .with_content(/^virt vtep2 profile profint mode static/)
    end

  end

  context 'with manage_service as false' do
    let :params do
    {
      :manage_service => false
    }
    end
    it 'should not start/stop service' do
      should contain_service('nexus1000v').without_ensure
    end
  end

  context 'with manage_service true and enable_service false' do
    let :params do
    {
      :manage_service => true,
      :enable         => false
    }
    end
    it 'should stop service' do
      should contain_service('nexus1000v').with_ensure('stopped')
    end
  end

  context 'verify sysctl setting with vteps_in_same_subnet true' do
    let :params do
    {
      :vteps_in_same_subnet => true
    }
    end
    it do
      should contain_sysctl__value('net.ipv4.conf.default.rp_filter').with_value('2')
      should contain_sysctl__value('net.ipv4.conf.all.rp_filter').with_value('2')
      should contain_sysctl__value('net.ipv4.conf.default.arp_ignore').with_value('1')
      should contain_sysctl__value('net.ipv4.conf.all.arp_ignore').with_value('1')
      should contain_sysctl__value('net.ipv4.conf.all.arp_announce').with_value('2')
      should contain_sysctl__value('net.ipv4.conf.default.arp_announce').with_value('2')
    end
  end

end
