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
# Unit tests for neutron::plugins::metering class
#

require 'spec_helper'

describe 'neutron::agents::metering' do

  let :pre_condition do
    "class { 'neutron':
      rabbit_password => 'passw0rd',
      service_plugins => ['neutron.services.metering.metering_plugin.MeteringPlugin'] }"
  end

  let :params do
    {}
  end

  let :default_params do
    { :package_ensure   => 'present',
      :enabled          => true,
      :debug            => false,
      :interface_driver => 'neutron.agent.linux.interface.OVSInterfaceDriver',
      :use_namespaces   => true,
      :measure_interval => '30',
      :report_interval  => '300'
    }
  end


  shared_examples_for 'neutron metering agent' do
    let :p do
      default_params.merge(params)
    end

    it { should contain_class('neutron::params') }

    it 'configures metering_agent.ini' do
      should contain_neutron_metering_agent_config('DEFAULT/debug').with_value(p[:debug]);
      should contain_neutron_metering_agent_config('DEFAULT/interface_driver').with_value(p[:interface_driver]);
      should contain_neutron_metering_agent_config('DEFAULT/use_namespaces').with_value(p[:use_namespaces]);
      should contain_neutron_metering_agent_config('DEFAULT/measure_interval').with_value(p[:measure_interval]);
      should contain_neutron_metering_agent_config('DEFAULT/report_interval').with_value(p[:report_interval]);
    end

    it 'installs neutron metering agent package' do
      if platform_params.has_key?(:metering_agent_package)
        should contain_package('neutron-metering-agent').with(
          :name   => platform_params[:metering_agent_package],
          :ensure => p[:package_ensure]
        )
        should contain_package('neutron').with_before(/Package\[neutron-metering-agent\]/)
        should contain_package('neutron-metering-agent').with_before(/Neutron_metering_agent_config\[.+\]/)
        should contain_package('neutron-metering-agent').with_before(/Neutron_config\[.+\]/)
      else
        should contain_package('neutron').with_before(/Neutron_metering_agent_config\[.+\]/)
      end
    end

    it 'configures neutron metering agent service' do
      should contain_service('neutron-metering-service').with(
        :name    => platform_params[:metering_agent_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]'
      )
    end

    context 'with manage_service as false' do
      before :each do
        params.merge!(:manage_service => false)
      end
      it 'should not start/stop service' do
        should contain_service('neutron-metering-service').without_ensure
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :metering_agent_package => 'neutron-metering-agent',
        :metering_agent_service => 'neutron-metering-agent' }
    end

    it_configures 'neutron metering agent'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :metering_agent_package => 'openstack-neutron-metering-agent',
        :metering_agent_service => 'neutron-metering-agent' }
    end

    it_configures 'neutron metering agent'
  end
end
