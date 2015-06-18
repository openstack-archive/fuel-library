#
# Copyright (C) 2014 Mirantis
#
# Author: Steapn Rogov <srogov@mirantis.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for glance::backend::vsphere class
#

require 'spec_helper'

describe 'glance::backend::vsphere' do

  let :pre_condition do
    'class { "glance::api": keystone_password => "pass" }'
  end

  shared_examples_for 'glance with vsphere backend' do

    context 'when default parameters' do
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
      it 'configures glance-api.conf' do
        should contain_glance_api_config('DEFAULT/default_store').with_value('vsphere')
        should contain_glance_api_config('DEFAULT/vmware_api_insecure').with_value('False')
        should contain_glance_api_config('DEFAULT/vmware_server_host').with_value('10.0.0.1')
        should contain_glance_api_config('DEFAULT/vmware_server_username').with_value('root')
        should contain_glance_api_config('DEFAULT/vmware_server_password').with_value('123456')
        should contain_glance_api_config('DEFAULT/vmware_datastore_name').with_value('Datastore')
        should contain_glance_api_config('DEFAULT/vmware_store_image_dir').with_value('/openstack_glance')
        should contain_glance_api_config('DEFAULT/vmware_task_poll_interval').with_value('5')
        should contain_glance_api_config('DEFAULT/vmware_api_retry_count').with_value('10')
        should contain_glance_api_config('DEFAULT/vmware_datacenter_path').with_value('Datacenter')
      end
    end

    context 'when overriding parameters' do
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
        should contain_glance_api_config('DEFAULT/vmware_api_insecure').with_value('True')
        should contain_glance_api_config('DEFAULT/vmware_task_poll_interval').with_value('6')
        should contain_glance_api_config('DEFAULT/vmware_api_retry_count').with_value('11')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'glance with vsphere backend'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'glance with vsphere backend'
  end
end
