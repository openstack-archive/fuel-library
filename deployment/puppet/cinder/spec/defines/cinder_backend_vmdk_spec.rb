require 'spec_helper'

describe 'cinder::backend::vmdk' do

  let(:title) { 'hippo' }

  let :params do
    {
        :host_ip => '172.16.16.16',
        :host_password => 'asdf',
        :host_username => 'user'
    }
  end

  let :optional_params do
    {
        :volume_folder => 'cinder-volume-folder',
        :api_retry_count => 5,
        :max_object_retrieval => 200,
        :task_poll_interval => 10,
        :image_transfer_timeout_secs => 3600,
        :wsdl_location => 'http://127.0.0.1:8080/vmware/SDK/wsdl/vim25/vimService.wsdl'
    }
  end

  it 'should configure vmdk driver in cinder.conf' do
    is_expected.to contain_cinder_config('hippo/volume_backend_name').with_value('hippo')
    is_expected.to contain_cinder_config('hippo/volume_driver').with_value('cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver')
    is_expected.to contain_cinder_config('hippo/vmware_host_ip').with_value(params[:host_ip])
    is_expected.to contain_cinder_config('hippo/vmware_host_username').with_value(params[:host_username])
    is_expected.to contain_cinder_config('hippo/vmware_host_password').with_value(params[:host_password])
    is_expected.to contain_cinder_config('hippo/vmware_volume_folder').with_value('cinder-volumes')
    is_expected.to contain_cinder_config('hippo/vmware_api_retry_count').with_value(10)
    is_expected.to contain_cinder_config('hippo/vmware_max_object_retrieval').with_value(100)
    is_expected.to contain_cinder_config('hippo/vmware_task_poll_interval').with_value(5)
    is_expected.to contain_cinder_config('hippo/vmware_image_transfer_timeout_secs').with_value(7200)
    is_expected.to_not contain_cinder_config('hippo/vmware_wsdl_location')
  end

  it 'installs suds python package' do
    is_expected.to contain_package('python-suds').with(
               :ensure => 'present')
  end

  context 'with optional parameters' do
    before :each do
      params.merge!(optional_params)
    end

    it 'should configure vmdk driver in cinder.conf' do
      is_expected.to contain_cinder_config('hippo/vmware_volume_folder').with_value(params[:volume_folder])
      is_expected.to contain_cinder_config('hippo/vmware_api_retry_count').with_value(params[:api_retry_count])
      is_expected.to contain_cinder_config('hippo/vmware_max_object_retrieval').with_value(params[:max_object_retrieval])
      is_expected.to contain_cinder_config('hippo/vmware_task_poll_interval').with_value(params[:task_poll_interval])
      is_expected.to contain_cinder_config('hippo/vmware_image_transfer_timeout_secs').with_value(params[:image_transfer_timeout_secs])
      is_expected.to contain_cinder_config('hippo/vmware_wsdl_location').with_value(params[:wsdl_location])
    end
  end

  context 'vmdk backend with additional configuration' do
    before do
      params.merge!({:extra_options => {'hippo/param1' => { 'value' => 'value1' }}})
    end

    it 'configure vmdk backend with additional configuration' do
      should contain_cinder_config('hippo/param1').with({
        :value => 'value1'
      })
    end
  end

end
