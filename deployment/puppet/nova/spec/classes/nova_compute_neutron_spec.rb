require 'spec_helper'
describe 'nova::compute::neutron' do

  context 'with default parameters' do
    it { is_expected.to contain_nova_config('libvirt/vif_driver').with_value('nova.virt.libvirt.vif.LibvirtGenericVIFDriver')}
    it { is_expected.to contain_nova_config('DEFAULT/force_snat_range').with(:value => '0.0.0.0/0') }
  end

  context 'when overriding params' do
    let :params do
      {:libvirt_vif_driver => 'foo' }
    end
    it { is_expected.to contain_nova_config('libvirt/vif_driver').with_value('foo')}
    it { is_expected.to contain_nova_config('DEFAULT/force_snat_range').with_ensure(:absent) }
  end

  context 'when overriding with a removed libvirt_vif_driver param' do
    let :params do
      {:libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver' }
    end

    it_raises 'a Puppet::Error', /nova.virt.libvirt.vif.LibvirtOpenVswitchDriver as vif_driver is removed from Icehouse/
  end

  context 'with force_snat_range parameter set to false' do
    let :params do
      { :force_snat_range => false, }
    end
    it { is_expected.to contain_nova_config('DEFAULT/force_snat_range').with_ensure('absent') }
  end

  context 'with force_snat_range parameter set to 10.0.0.0/24' do
    let :params do
      { :force_snat_range => '10.0.0.0/24', }
    end

    it { is_expected.to contain_nova_config('DEFAULT/force_snat_range').with_value('10.0.0.0/24') }
  end

  context 'with force_snat_range parameter set to fe80::/64' do
    let :params do
      { :force_snat_range => 'fe80::/64', }
    end

    it { is_expected.to contain_nova_config('DEFAULT/force_snat_range').with_value('fe80::/64') }
  end

  context 'with force_snat_range parameter set ip without mask' do
    let :params do
      { :force_snat_range => '10.0.0.0', }
    end

    it_raises 'a Puppet::Error', /force_snat_range should be IPv4 or IPv6 CIDR notation/
  end

end
