require 'spec_helper'
describe 'nova::compute::neutron' do

  it { should contain_nova_config('DEFAULT/libvirt_use_virtio_for_bridges').with_value(true)}
  it { should contain_nova_config('DEFAULT/libvirt_vif_driver').with_value('nova.virt.libvirt.vif.LibvirtOpenVswitchDriver')}

  context 'when overriding params' do
    let :params do
      {:libvirt_vif_driver => 'foo' }
    end
    it { should contain_nova_config('DEFAULT/libvirt_vif_driver').with_value('foo')}
  end

end
