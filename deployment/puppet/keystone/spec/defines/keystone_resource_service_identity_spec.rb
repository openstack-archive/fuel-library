#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
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

require 'spec_helper'

describe 'keystone::resource::service_identity' do

  let (:title) { 'neutron' }

  let :required_params do
    { :password     => 'secrete',
      :service_type => 'network',
      :admin_url    => 'http://192.168.0.1:9696',
      :internal_url => 'http://10.0.0.1:9696',
      :public_url   => 'http://7.7.7.7:9696' }
  end

  shared_examples 'keystone::resource::service_identity examples' do

    context 'with only required parameters' do
      let :params do
        required_params
      end

      it { is_expected.to contain_keystone_user(title).with(
        :ensure   => 'present',
        :password => 'secrete',
        :email    => 'neutron@localhost',
        :tenant   => 'services',
      )}

      it { is_expected.to contain_keystone_user_role("#{title}@services").with(
        :ensure => 'present',
        :roles  => ['admin'],
      )}

      it { is_expected.to contain_keystone_service(title).with(
        :ensure      => 'present',
        :type        => 'network',
        :description => 'neutron service',
      )}

      it { is_expected.to contain_keystone_endpoint("RegionOne/#{title}").with(
        :ensure       => 'present',
        :public_url   => 'http://7.7.7.7:9696',
        :internal_url => 'http://10.0.0.1:9696',
        :admin_url    => 'http://192.168.0.1:9696',
      )}
    end

    context 'when omitting a required parameter password' do
      let :params do
        required_params.delete(:password)
      end
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

  end

  context 'on a Debian osfamily' do
    let :facts do
      { :osfamily => "Debian" }
    end

    include_examples 'keystone::resource::service_identity examples'
  end

  context 'on a RedHat osfamily' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    include_examples 'keystone::resource::service_identity examples'
  end
end
