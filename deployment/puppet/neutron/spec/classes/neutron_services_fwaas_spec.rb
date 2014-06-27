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
# Unit tests for neutron::services::fwaas class
#

require 'spec_helper'

describe 'neutron::services::fwaas' do
  let :params do
    {}
  end

  let :default_params do
    { :driver   => 'neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver',
      :enabled  => true }
  end

  shared_examples_for 'neutron fwaas service plugin' do
    let :params_hash do
      default_params.merge(params)
    end

    it 'configures driver in fwaas_driver.ini' do
      params_hash.each_pair do |config,value|
        should contain_neutron_fwaas_service_config('fwaas/driver').with_value('neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver')
        should contain_neutron_fwaas_service_config('fwaas/enabled').with_value('true')
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :l3_agent_package => 'neutron-l3-agent' }
    end

    it_configures 'neutron fwaas service plugin'

  end

  context 'on Red Hat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :package_name => 'openstack-neutron' }
    end

    it_configures 'neutron fwaas service plugin'

  end

end
