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
#
# Unit tests for ceilometer::agent::notification
#

require 'spec_helper'

describe 'ceilometer::agent::notification' do

  let :pre_condition do
    "class { 'ceilometer': metering_secret => 's3cr3t' }"
  end

  let :params do
    { :ack_on_event_error => true,
      :store_events       => false }
  end

  shared_examples_for 'ceilometer-agent-notification' do

    it { should contain_class('ceilometer::params') }

    it 'installs ceilometer agent notification package' do
      should contain_package(platform_params[:agent_notification_package_name])
    end

    it 'configures ceilometer agent notification service' do
      should contain_service('ceilometer-agent-notification').with(
        :ensure     => 'running',
        :name       => platform_params[:agent_notification_service_name],
        :enable     => true,
        :hasstatus  => true,
        :hasrestart => true
      )
    end

    it 'configures notifications parameters in ceilometer.conf' do
      should contain_ceilometer_config('notification/ack_on_event_error').with_value( params[:ack_on_event_error] )
      should contain_ceilometer_config('notification/store_events').with_value( params[:store_events] )
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :agent_notification_package_name => 'ceilometer-agent-notification',
        :agent_notification_service_name => 'ceilometer-agent-notification' }
    end

    it_configures 'ceilometer-agent-notification'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :agent_notification_package_name => 'openstack-ceilometer-notification',
        :agent_notification_service_name => 'openstack-ceilometer-notification' }
    end

    it_configures 'ceilometer-agent-notification'
  end

end
