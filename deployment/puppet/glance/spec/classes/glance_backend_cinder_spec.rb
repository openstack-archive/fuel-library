#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
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
# Unit tests for glance::backend::cinder class
#

require 'spec_helper'

describe 'glance::backend::cinder' do

  let :pre_condition do
    'class { "glance::api": keystone_password => "pass" }'
  end

  shared_examples_for 'glance with cinder backend' do

    context 'when default parameters' do

      it 'configures glance-api.conf' do
        should contain_glance_api_config('glance_store/default_store').with_value('cinder')
        should contain_glance_api_config('DEFAULT/cinder_api_insecure').with_value(false)
        should contain_glance_api_config('DEFAULT/cinder_catalog_info').with_value('volume:cinder:publicURL')
        should contain_glance_api_config('DEFAULT/cinder_http_retries').with_value('3')
        should contain_glance_api_config('DEFAULT/cinder_ca_certificates_file').with(:ensure => 'absent')
        should contain_glance_api_config('DEFAULT/cinder_endpoint_template').with(:ensure => 'absent')
      end
      it 'configures glance-cache.conf' do
        should contain_glance_cache_config('DEFAULT/cinder_api_insecure').with_value(false)
        should contain_glance_cache_config('DEFAULT/cinder_catalog_info').with_value('volume:cinder:publicURL')
        should contain_glance_cache_config('DEFAULT/cinder_http_retries').with_value('3')
        should contain_glance_cache_config('DEFAULT/cinder_ca_certificates_file').with(:ensure => 'absent')
        should contain_glance_cache_config('DEFAULT/cinder_endpoint_template').with(:ensure => 'absent')
      end
    end

    context 'when overriding parameters' do
      let :params do
        {
          :cinder_api_insecure         => true,
          :cinder_ca_certificates_file => '/etc/ssh/ca.crt',
          :cinder_catalog_info         => 'volume:cinder:internalURL',
          :cinder_endpoint_template    => 'http://srv-foo:8776/v1/%(project_id)s',
          :cinder_http_retries         => '10',
        }
      end
      it 'configures glance-api.conf' do
        should contain_glance_api_config('glance_store/default_store').with_value('cinder')
        should contain_glance_api_config('DEFAULT/cinder_api_insecure').with_value(true)
        should contain_glance_api_config('DEFAULT/cinder_ca_certificates_file').with_value('/etc/ssh/ca.crt')
        should contain_glance_api_config('DEFAULT/cinder_catalog_info').with_value('volume:cinder:internalURL')
        should contain_glance_api_config('DEFAULT/cinder_endpoint_template').with_value('http://srv-foo:8776/v1/%(project_id)s')
        should contain_glance_api_config('DEFAULT/cinder_http_retries').with_value('10')
      end
      it 'configures glance-cache.conf' do
        should contain_glance_cache_config('DEFAULT/cinder_api_insecure').with_value(true)
        should contain_glance_cache_config('DEFAULT/cinder_ca_certificates_file').with_value('/etc/ssh/ca.crt')
        should contain_glance_cache_config('DEFAULT/cinder_catalog_info').with_value('volume:cinder:internalURL')
        should contain_glance_cache_config('DEFAULT/cinder_endpoint_template').with_value('http://srv-foo:8776/v1/%(project_id)s')
        should contain_glance_cache_config('DEFAULT/cinder_http_retries').with_value('10')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'glance with cinder backend'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'glance with cinder backend'
  end
end
