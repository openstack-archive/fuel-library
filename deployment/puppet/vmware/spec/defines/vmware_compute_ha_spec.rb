require 'spec_helper'

describe 'vmware::compute::ha' do
  let(:title) { 'cluster1' }

  let(:params) { { :index => '0' } }

  it 'must create /etc/nova/nova-compute.d directory' do
    should contain_file('/etc/nova/nova-compute.d').with({
      'ensure' => 'directory',
      'owner'  => 'nova',
      'group'  => 'nova',
      'mode'   => '0750'
    })
  end

  it 'should create service p_nova_compute_vmware_0' do
    should contain_cs_resource('p_nova_compute_vmware_0').with({
      'primitive_class' => 'ocf',
      'provided_by' => 'mirantis',
    })
  end

  it 'should create service p_nova_compute_vmware_0' do
    should contain_service('p_nova_compute_vmware_0')
  end

  it 'should apply configuration file before corosync resource' do
    should contain_file('/etc/nova/nova-compute.d/vmware-0.conf').that_comes_before('Cs_resource[p_nova_compute_vmware_0]')
  end
end
