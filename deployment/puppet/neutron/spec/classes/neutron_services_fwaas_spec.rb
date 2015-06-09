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
  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  let :params do
    {}
  end

  let :default_params do
    { :driver               => 'neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver',
      :enabled              => true,
      :vpnaas_agent_package => false }
  end

  shared_examples_for 'neutron fwaas service plugin' do
    let :params_hash do
      default_params.merge(params)
    end

    it 'configures driver in fwaas_driver.ini' do
      is_expected.to contain_neutron_fwaas_service_config('fwaas/driver').with_value('neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver')
      is_expected.to contain_neutron_fwaas_service_config('fwaas/enabled').with_value('true')
    end
  end

  context 'on Ubuntu platforms' do
    let :facts do
      default_facts.merge(
        { :osfamily        => 'Debian',
          :operatingsystem => 'Ubuntu' })
    end

    it_configures 'neutron fwaas service plugin'

    it 'installs neutron fwaas package' do
      is_expected.to contain_package('python-neutron-fwaas').with(
        :ensure => 'present',
        :tag    => 'openstack'
      )
    end
  end

  context 'on Debian platforms without VPNaaS' do
    let :facts do
      default_facts.merge(
        { :osfamily        => 'Debian',
          :operatingsystem => 'Debian' })
    end

    it_configures 'neutron fwaas service plugin'

    it 'installs neutron fwaas package' do
      is_expected.to contain_package('python-neutron-fwaas').with(
        :ensure => 'present',
        :tag    => 'openstack'
      )
    end
  end

  context 'on Debian platforms with VPNaaS' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :params do
      { :vpnaas_agent_package => true }
    end

    it_configures 'neutron fwaas service plugin'

    it 'installs neutron vpnaas agent package' do
      is_expected.to contain_package('neutron-vpn-agent').with(
        :ensure => 'present',
        :tag    => 'openstack'
      )
    end
  end

  context 'on Red Hat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    it_configures 'neutron fwaas service plugin'

    it 'installs neutron fwaas service package' do
      is_expected.to contain_package('openstack-neutron-fwaas').with_ensure('present')
    end
  end

end
