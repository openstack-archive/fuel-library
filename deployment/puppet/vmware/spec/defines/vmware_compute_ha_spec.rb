require 'spec_helper'

describe 'vmware::compute::ha' do
  let(:title) { '0' }

  let(:params) { {
    :availability_zone_name => 'vCenter',
    :vc_cluster             => 'prod-cluster',
    :vc_host                => '10.10.0.1',
    :vc_user                => 'admin@vsphere.local',
    :vc_password            => 'pass',
    :service_name           => 'prod'
  } }

  it 'must create /etc/nova/nova-compute.d directory' do
    should contain_file('/etc/nova/nova-compute.d').with({
      'ensure' => 'directory',
      'owner'  => 'nova',
      'group'  => 'nova',
      'mode'   => '0750'
    })
  end

  it 'should create service p_nova_compute_vmware_vCenter-prod' do
    should contain_pcmk_resource('p_nova_compute_vmware_vCenter-prod').with({
      'primitive_class'    => 'ocf',
      'primitive_provider' => 'fuel',
    })
  end

  it 'should create service p_nova_compute_vmware_vCenter-prod' do
    should contain_service('p_nova_compute_vmware_vCenter-prod')
  end

  it 'should apply configuration file before corosync resource' do
    should contain_file('/etc/nova/nova-compute.d/vmware-vCenter_prod.conf').that_comes_before('Pcmk_resource[p_nova_compute_vmware_vCenter-prod]')
  end
end
