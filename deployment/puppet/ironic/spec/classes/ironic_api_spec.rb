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
# Unit tests for ironic::api class
#

require 'spec_helper'

describe 'ironic::api' do

  let :default_params do
    { :package_ensure => 'present',
      :enabled        => true,
      :port           => '6385',
      :max_limit      => '1000',
      :host_ip        => '0.0.0.0',
      :admin_user     => 'ironic',
    }
  end

  let :params do
    { :admin_password => 'thepassword' }
  end

  shared_examples_for 'ironic api' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('ironic::params') }
    it { is_expected.to contain_class('ironic::policy') }

    it 'installs ironic api package' do
      if platform_params.has_key?(:api_package)
        is_expected.to contain_package('ironic-api').with(
          :name   => platform_params[:api_package],
          :ensure => p[:package_ensure],
          :tag    => 'openstack'
        )
        is_expected.to contain_package('ironic-api').with_before(/Ironic_config\[.+\]/)
        is_expected.to contain_package('ironic-api').with_before(/Service\[ironic-api\]/)
      end
    end

    it 'ensure ironic api service is running' do
      is_expected.to contain_service('ironic-api').with('hasstatus' => true)
    end

    it 'configures ironic.conf' do
      is_expected.to contain_ironic_config('api/port').with_value(p[:port])
      is_expected.to contain_ironic_config('api/host_ip').with_value(p[:host_ip])
      is_expected.to contain_ironic_config('api/max_limit').with_value(p[:max_limit])
      is_expected.to contain_ironic_config('keystone_authtoken/admin_password').with_value(p[:admin_password])
      is_expected.to contain_ironic_config('keystone_authtoken/admin_user').with_value(p[:admin_user])
      is_expected.to contain_ironic_config('keystone_authtoken/auth_uri').with_value('http://127.0.0.1:5000/')
      is_expected.to contain_ironic_config('neutron/url').with_value('http://127.0.0.1:9696/')
    end

    context 'when overriding parameters' do
      before :each do
        params.merge!(
          :port => '3430',
          :host_ip => '127.0.0.1',
          :max_limit => '10',
          :auth_protocol => 'https',
          :auth_host => '1.2.3.4'
        )
      end
      it 'should replace default parameter with new value' do
        is_expected.to contain_ironic_config('api/port').with_value(p[:port])
        is_expected.to contain_ironic_config('api/host_ip').with_value(p[:host_ip])
        is_expected.to contain_ironic_config('api/max_limit').with_value(p[:max_limit])
        is_expected.to contain_ironic_config('keystone_authtoken/auth_uri').with_value('https://1.2.3.4:5000/')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :api_package => 'ironic-api',
        :api_service => 'ironic-api' }
    end

    it_configures 'ironic api'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :api_service => 'ironic-api' }
    end

    it_configures 'ironic api'
  end

end
