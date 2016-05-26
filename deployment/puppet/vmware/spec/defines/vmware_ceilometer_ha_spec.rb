require 'spec_helper'

describe 'vmware::ceilometer::ha' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      xit { is_expected.to compile.with_all_deps }

      let(:params) do
        {
            :availability_zone_name => 'vCenter',
            :vc_cluster => 'prod-cluster',
            :vc_host => '10.10.0.1',
            :vc_user => 'admin@vsphere.local',
            :vc_password => 'pass',
            :service_name => 'prod'
        }
      end

      xit 'must create /etc/ceilometer/ceilometer-compute.d directory' do
        should contain_file('/etc/ceilometer/ceilometer-compute.d').with({
                                                                             'ensure' => 'directory',
                                                                             'owner' => 'ceilometer',
                                                                             'group' => 'ceilometer',
                                                                             'mode' => '0750'
                                                                         })
      end

      xit 'should create service p_ceilometer_agent_compute_vmware_vCenter_prod' do
        should contain_pacemaker_resource('p_ceilometer_agent_compute_vmware_vCenter_prod').with({
                                                                                                'primitive_class' => 'ocf',
                                                                                                'primitive_provider' => 'fuel',
                                                                                            })
      end

      xit 'should create service p_ceilometer_agent_compute_vmware_vCenter_prod' do
        should contain_service('p_ceilometer_agent_compute_vmware_vCenter_prod')
      end

      xit 'should apply configuration file before corosync resource' do
        should contain_file('/etc/ceilometer/ceilometer-compute.d/vmware-vCenter_prod.conf').that_comes_before('Pacemaker_resource[p_ceilometer_agent_compute_vmware_vCenter_prod]')
      end

    end
  end
end
