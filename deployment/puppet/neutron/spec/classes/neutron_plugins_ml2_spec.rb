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
# Unit tests for neutron::plugins::ml2 class
#

require 'spec_helper'

describe 'neutron::plugins::ml2' do

  let :pre_condition do
    "class { 'neutron':
      rabbit_password => 'passw0rd',
      core_plugin     => 'neutron.plugins.ml2.plugin.Ml2Plugin' }"
  end

  let :default_params do
    { :type_drivers          => ['local', 'flat', 'vlan', 'gre', 'vxlan'],
      :tenant_network_types  => ['local', 'flat', 'vlan', 'gre', 'vxlan'],
      :mechanism_drivers     => ['openvswitch', 'linuxbridge'],
      :flat_networks         => ['*'],
      :network_vlan_ranges   => ['10:50'],
      :tunnel_id_ranges      => ['20:100'],
      :vxlan_group           => '224.0.0.1',
      :vni_ranges            => ['10:100'],
      :package_ensure        => 'present' }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  let :params do
    {}
  end

  shared_examples_for 'neutron plugin ml2' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('neutron::params') }

    it 'configures neutron.conf' do
        is_expected.to contain_neutron_config('DEFAULT/core_plugin').with_value('neutron.plugins.ml2.plugin.Ml2Plugin')
    end

    it 'configures ml2_conf.ini' do
      is_expected.to contain_neutron_plugin_ml2('ml2/type_drivers').with_value(p[:type_drivers].join(','))
      is_expected.to contain_neutron_plugin_ml2('ml2/tenant_network_types').with_value(p[:tenant_network_types].join(','))
      is_expected.to contain_neutron_plugin_ml2('ml2/mechanism_drivers').with_value(p[:mechanism_drivers].join(','))
    end

    it 'creates plugin symbolic link' do
      is_expected.to contain_file('/etc/neutron/plugin.ini').with(
        :ensure  => 'link',
        :target  => '/etc/neutron/plugins/ml2/ml2_conf.ini'
      )
    end

    it 'installs ml2 package (if any)' do
      if platform_params.has_key?(:ml2_server_package)
        is_expected.to contain_package('neutron-plugin-ml2').with(
          :name   => platform_params[:ml2_server_package],
          :ensure => p[:package_ensure],
          :tag    => 'openstack'
        )
        is_expected.to contain_package('neutron-plugin-ml2').with_before(/Neutron_plugin_ml2\[.+\]/)
      end
    end

    context 'configure ml2 with bad driver value' do
      before :each do
       params.merge!(:type_drivers => ['foobar'])
      end

      it_raises 'a Puppet::Error', /type_driver unknown./
    end

    context 'when using flat driver' do
      before :each do
        params.merge!(:flat_networks => ['eth1', 'eth2'])
      end
      it 'configures flat_networks' do
        is_expected.to contain_neutron_plugin_ml2('ml2_type_flat/flat_networks').with_value(p[:flat_networks].join(','))
      end
    end

    context 'when using gre driver with valid values' do
      before :each do
        params.merge!(:tunnel_id_ranges => ['0:20', '40:60'])
      end
      it 'configures gre_networks with valid ranges' do
        is_expected.to contain_neutron_plugin_ml2('ml2_type_gre/tunnel_id_ranges').with_value(p[:tunnel_id_ranges].join(','))
      end
    end

    context 'when using gre driver with invalid values' do
      before :each do
       params.merge!(:tunnel_id_ranges => ['0:20', '40:100000000'])
      end

      it_raises 'a Puppet::Error', /tunnel id ranges are to large./
    end

    context 'when using vlan driver with valid values' do
      before :each do
        params.merge!(:network_vlan_ranges => ['1:20', '400:4094'])
      end
      it 'configures vlan_networks with 1:20 and 400:4094 VLAN ranges' do
        is_expected.to contain_neutron_plugin_ml2('ml2_type_vlan/network_vlan_ranges').with_value(p[:network_vlan_ranges].join(','))
      end
    end

    context 'when using vlan driver with invalid vlan id' do
      before :each do
       params.merge!(:network_vlan_ranges => ['1:20', '400:4099'])
      end

      it_raises 'a Puppet::Error', /vlan id are invalid./
    end

    context 'when using vlan driver with invalid vlan range' do
      before :each do
        params.merge!(:network_vlan_ranges => ['2938:1'])
      end

      it_raises 'a Puppet::Error', /vlan ranges are invalid./
    end

    context 'when using vxlan driver with valid values' do
      before :each do
        params.merge!(:vni_ranges => ['40:300', '500:1000'], :vxlan_group => '224.1.1.1')
      end
      it 'configures vxlan_networks with 224.1.1.1 vxlan group' do
        is_expected.to contain_neutron_plugin_ml2('ml2_type_vxlan/vni_ranges').with_value(p[:vni_ranges].join(','))
        is_expected.to contain_neutron_plugin_ml2('ml2_type_vxlan/vxlan_group').with_value(p[:vxlan_group])
      end
    end

    context 'when using vxlan driver with invalid vxlan group' do
      before :each do
        params.merge!(:vxlan_group => '192.1.1.1')
      end

      it_raises 'a Puppet::Error', /is not valid for vxlan_group./
    end

    context 'when using vxlan driver with invalid vni_range' do
      before :each do
        params.merge!(:vni_ranges => ['2938:1'])
      end

      it_raises  'a Puppet::Error', /vni ranges are invalid./
    end

    context 'when overriding package ensure state' do
      before :each do
        params.merge!(:package_ensure => 'latest')
      end
      it 'overrides package ensure state (if possible)' do
        if platform_params.has_key?(:ml2_server_package)
          is_expected.to contain_package('neutron-plugin-ml2').with(
            :name   => platform_params[:ml2_server_package],
            :ensure => params[:package_ensure],
            :tag    => 'openstack'
          )
        end
      end
    end

    context 'when running sriov mechanism driver' do
      before :each do
        params.merge!(
          :mechanism_drivers    => ['openvswitch', 'sriovnicswitch'],
          :sriov_agent_required => true,
        )
      end
      it 'configures sriov mechanism driver with agent_enabled' do
        is_expected.to contain_neutron_plugin_ml2('ml2_sriov/supported_pci_vendor_dev').with_value(['15b3:1004,8086:10ca'])
        is_expected.to contain_neutron_plugin_ml2('ml2_sriov/agent_required').with_value('true')
      end
    end

    context 'on Ubuntu operating systems' do
      before do
        facts.merge!({:operatingsystem => 'Ubuntu'})
      end

      it 'configures /etc/default/neutron-server' do
        is_expected.to contain_file_line('/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG').with(
          :path    => '/etc/default/neutron-server',
          :match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
          :line    => 'NEUTRON_PLUGIN_CONFIG=/etc/neutron/plugin.ini',
          :require => ['File[/etc/default/neutron-server]','File[/etc/neutron/plugin.ini]']
        )
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :platform_params do
      {}
    end

    context 'on Ubuntu operating systems' do
      before do
        facts.merge!({:operatingsystem => 'Ubuntu'})
        platform_params.merge!(:ml2_server_package => 'neutron-plugin-ml2')
      end

      it_configures 'neutron plugin ml2'
    end

    context 'on non-Ubuntu operating systems' do
      before do
        facts.merge!({:operatingsystem => 'Debian'})
      end

      it_configures 'neutron plugin ml2'
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :platform_params do
      { :ml2_server_package => 'openstack-neutron-ml2' }
    end

    it_configures 'neutron plugin ml2'
  end

end
