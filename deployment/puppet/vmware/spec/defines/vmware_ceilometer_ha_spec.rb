require 'spec_helper'

describe 'vmware::ceilometer::ha' do
  let(:params) { {
    :availability_zone_name => 'vCenter',
    :vc_cluster             => 'prod-cluster',
    :vc_host                => '10.10.0.1',
    :vc_user                => 'admin@vsphere.local',
    :vc_password            => 'pass',
    :service_name           => 'prod'
  } }

  it 'must create /etc/ceilometer/ceilometer-compute.d directory' do
    should contain_file('/etc/ceilometer/ceilometer-compute.d').with({
      'ensure' => 'directory',
      'owner'  => 'ceilometer',
      'group'  => 'ceilometer',
      'mode'   => '0750'
    })
  end

  it 'should create service p_ceilometer_agent_compute_vmware_vCenter_prod' do
    should contain_pcmk_resource('p_ceilometer_agent_compute_vmware_vCenter_prod').with({
      'primitive_class'    => 'ocf',
      'primitive_provider' => 'fuel',
    })
  end

  it 'should create service p_ceilometer_agent_compute_vmware_vCenter_prod' do
    should contain_service('p_ceilometer_agent_compute_vmware_vCenter_prod')
  end

  it 'should apply configuration file before corosync resource' do
    should contain_file('/etc/ceilometer/ceilometer-compute.d/vmware-vCenter_prod.conf').that_comes_before('Pcmk_resource[p_ceilometer_agent_compute_vmware_vCenter_prod]')
  end
end
