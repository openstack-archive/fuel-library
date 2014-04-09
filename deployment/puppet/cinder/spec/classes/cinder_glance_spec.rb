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
# Unit tests for cinder::glance class
#

require 'spec_helper'

describe 'cinder::glance' do

  let :default_params do
    { :glance_api_version         => '2',
      :glance_num_retries         => '0',
      :glance_api_insecure        => false,
      :glance_api_ssl_compression => false }
  end

  let :params do
    {}
  end

  shared_examples_for 'cinder with glance' do
    let :p do
      default_params.merge(params)
    end

    it 'configures cinder.conf with default params' do
      should contain_cinder_config('DEFAULT/glance_api_version').with_value(p[:glance_api_version])
      should contain_cinder_config('DEFAULT/glance_num_retries').with_value(p[:glance_num_retries])
      should contain_cinder_config('DEFAULT/glance_api_insecure').with_value(p[:glance_api_insecure])
    end

     context 'configure cinder with one glance server' do
       before :each do
        params.merge!(:glance_api_servers => '10.0.0.1:9292')
       end
       it 'should configure one glance server' do
         should contain_cinder_config('DEFAULT/glance_api_servers').with_value(p[:glance_api_servers])
       end
     end

     context 'configure cinder with two glance servers' do
       before :each do
        params.merge!(:glance_api_servers => ['10.0.0.1:9292','10.0.0.2:9292'])
       end
       it 'should configure two glance servers' do
         should contain_cinder_config('DEFAULT/glance_api_servers').with_value(p[:glance_api_servers].join(','))
       end
     end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'cinder with glance'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'cinder with glance'
  end

end
