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
# Unit tests for ironic::conductor class
#

require 'spec_helper'

describe 'ironic::conductor' do

  let :default_params do
    { :package_ensure    => 'present',
      :enabled           => true,
      :max_time_interval => '120' }
  end

  let :params do
    {}
  end

  shared_examples_for 'ironic conductor' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('ironic::params') }

    it 'installs ironic conductor package' do
      if platform_params.has_key?(:conductor_package)
        is_expected.to contain_package('ironic-conductor').with(
          :name   => platform_params[:conductor_package],
          :ensure => p[:package_ensure],
          :tag    => 'openstack'
        )
        is_expected.to contain_package('ironic-conductor').with_before(/Ironic_config\[.+\]/)
        is_expected.to contain_package('ironic-conductor').with_before(/Service\[ironic-conductor\]/)
      end
    end

    it 'ensure ironic conductor service is running' do
      is_expected.to contain_service('ironic-conductor').with('hasstatus' => true)
    end

    it 'configures ironic.conf' do
      is_expected.to contain_ironic_config('conductor/max_time_interval').with_value(p[:max_time_interval])
    end

    context 'when overriding parameters' do
      before :each do
        params.merge!(:max_time_interval => '50')
      end
      it 'should replace default parameter with new value' do
        is_expected.to contain_ironic_config('conductor/max_time_interval').with_value(p[:max_time_interval])
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :conductor_package => 'ironic-conductor',
        :conductor_service => 'ironic-conductor' }
    end

    it_configures 'ironic conductor'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :conductor_service => 'ironic-conductor' }
    end

    it_configures 'ironic conductor'
  end

end
