require 'spec_helper'
describe 'nova::compute::neutron' do

  it { should contain_nova_config('libvirt/vif_driver').with_value('nova.virt.libvirt.vif.LibvirtGenericVIFDriver')}

  context 'when overriding params' do
    let :params do
      {:libvirt_vif_driver => 'foo' }
    end
    it { should contain_nova_config('libvirt/vif_driver').with_value('foo')}
  end

  context 'when overriding with a removed libvirt_vif_driver param' do
    let :params do
      {:libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver' }
    end
    it 'should fails to configure libvirt_vif_driver with old OVS driver' do
       expect { subject }.to raise_error(Puppet::Error, /nova.virt.libvirt.vif.LibvirtOpenVswitchDriver as vif_driver is removed from Icehouse/)
    end
  end

end
