require 'spec_helper'

describe 'nova::compute::vmware' do

  let :params do
    {:host_ip => '127.0.0.1',
     :host_username => 'root',
     :host_password => 'passw0rd',
     :cluster_name => 'cluster1'}
  end

  let :optional_params do
    {:api_retry_count => 10,
     :maximum_objects => 100,
     :task_poll_interval => 10.5,
     :use_linked_clone => false,
     :wsdl_location => 'http://127.0.0.1:8080/vmware/SDK/wsdl/vim25/vimService.wsdl'}
  end

  it 'configures vmwareapi in nova.conf' do
    is_expected.to contain_nova_config('DEFAULT/compute_driver').with_value('vmwareapi.VMwareVCDriver')
    is_expected.to contain_nova_config('VMWARE/host_ip').with_value(params[:host_ip])
    is_expected.to contain_nova_config('VMWARE/host_username').with_value(params[:host_username])
    is_expected.to contain_nova_config('VMWARE/host_password').with_value(params[:host_password])
    is_expected.to contain_nova_config('VMWARE/cluster_name').with_value(params[:cluster_name])
    is_expected.to contain_nova_config('VMWARE/api_retry_count').with_value(5)
    is_expected.to contain_nova_config('VMWARE/maximum_objects').with_value(100)
    is_expected.to contain_nova_config('VMWARE/task_poll_interval').with_value(5.0)
    is_expected.to contain_nova_config('VMWARE/use_linked_clone').with_value(true)
    is_expected.to_not contain_nova_config('VMWARE/wsdl_location')
  end

  it 'installs suds python package' do
    is_expected.to contain_package('python-suds').with(
               :ensure => 'present'
                )
  end

  context 'with optional parameters' do
    before :each do
      params.merge!(optional_params)
    end

    it 'configures vmwareapi in nova.conf' do
      is_expected.to contain_nova_config('VMWARE/api_retry_count').with_value(params[:api_retry_count])
      is_expected.to contain_nova_config('VMWARE/maximum_objects').with_value(params[:maximum_objects])
      is_expected.to contain_nova_config('VMWARE/task_poll_interval').with_value(params[:task_poll_interval])
      is_expected.to contain_nova_config('VMWARE/use_linked_clone').with_value(false)
      is_expected.to contain_nova_config('VMWARE/wsdl_location').with_value(params[:wsdl_location])
    end
  end
end
