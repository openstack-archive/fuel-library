require 'spec_helper'

describe 'glance::backend::vsphere' do
  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :params do
    {
      :vcenter_host       => '10.0.0.1',
      :vcenter_user       => 'root',
      :vcenter_password   => '123456',
      :vcenter_datacenter => 'Datacenter',
      :vcenter_datastore  => 'Datastore',
      :vcenter_image_dir  => '/openstack_glance',
    }
  end

  let :pre_condition do
    'class { "glance::api": keystone_password => "pass" }'
  end

  describe 'when default parameters' do

    it 'configures glance-api.conf' do
      should contain_glance_api_config('glance_store/default_store').with_value('vsphere')
      should contain_glance_api_config('glance_store/vmware_api_insecure').with_value('False')
      should contain_glance_api_config('glance_store/vmware_server_host').with_value('10.0.0.1')
      should contain_glance_api_config('glance_store/vmware_server_username').with_value('root')
      should contain_glance_api_config('glance_store/vmware_server_password').with_value('123456')
      should contain_glance_api_config('glance_store/vmware_datastore_name').with_value('Datastore')
      should contain_glance_api_config('glance_store/vmware_store_image_dir').with_value('/openstack_glance')
      should contain_glance_api_config('glance_store/vmware_task_poll_interval').with_value('5')
      should contain_glance_api_config('glance_store/vmware_api_retry_count').with_value('10')
      should contain_glance_api_config('glance_store/vmware_datacenter_path').with_value('Datacenter')
    end
  end

  describe 'when overriding parameters' do
    let :params do
      {
        :vcenter_host               => '10.0.0.1',
        :vcenter_user               => 'root',
        :vcenter_password           => '123456',
        :vcenter_datacenter         => 'Datacenter',
        :vcenter_datastore          => 'Datastore',
        :vcenter_image_dir          => '/openstack_glance',
        :vcenter_api_insecure       => 'True',
        :vcenter_task_poll_interval => '6',
        :vcenter_api_retry_count    => '11',
      }
    end

    it 'configures glance-api.conf' do
      should contain_glance_api_config('glance_store/vmware_api_insecure').with_value('True')
      should contain_glance_api_config('glance_store/vmware_task_poll_interval').with_value('6')
      should contain_glance_api_config('glance_store/vmware_api_retry_count').with_value('11')
    end
  end
end
