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
# Unit tests for neutron::server::notifications class
#

require 'spec_helper'

describe 'neutron::server::notifications' do
    let :pre_condition do
        'define keystone_user() {}'
    end

    let :default_params do
        {
            :notify_nova_on_port_status_changes => true,
            :notify_nova_on_port_data_changes   => true,
            :send_events_interval               => '2',
            :nova_url                           => 'http://127.0.0.1:8774/v2',
            :auth_plugin                        => 'password',
            :username                           => 'nova',
            :tenant_name                        => 'services',
            :project_domain_id                  => 'default',
            :project_name                       => 'services',
            :user_domain_id                     => 'default',
            :auth_url                           => 'http://127.0.0.1:35357',
            :nova_admin_auth_url                => 'http://127.0.0.1:35357/v2.0',
            :nova_admin_username                => 'nova',
            :nova_admin_tenant_name             => 'services',
            :nova_region_name                   => nil,
        }
    end

    let :default_facts do
      { :operatingsystem           => 'default',
        :operatingsystemrelease    => 'default'
      }
    end

    let :params do
        {
            :password  => 'secrete',
            :tenant_id => 'UUID'
        }
    end

    shared_examples_for 'neutron server notifications' do
        let :p do
            default_params.merge(params)
        end

        it 'configure neutron.conf' do
            is_expected.to contain_neutron_config('DEFAULT/notify_nova_on_port_status_changes').with_value(true)
            is_expected.to contain_neutron_config('DEFAULT/notify_nova_on_port_data_changes').with_value(true)
            is_expected.to contain_neutron_config('DEFAULT/send_events_interval').with_value('2')
            is_expected.to contain_neutron_config('DEFAULT/nova_url').with_value('http://127.0.0.1:8774/v2')
            is_expected.to contain_neutron_config('nova/auth_url').with_value('http://127.0.0.1:35357')
            is_expected.to contain_neutron_config('nova/username').with_value('nova')
            is_expected.to contain_neutron_config('nova/password').with_value('secrete')
            is_expected.to contain_neutron_config('nova/password').with_secret( true )
            is_expected.to contain_neutron_config('nova/tenant_id').with_value('UUID')
            is_expected.to contain_neutron_config('nova/region_name').with_ensure('absent')
            is_expected.not_to contain_neutron_config('DEFAULT/nova_admin_auth_url')
            is_expected.not_to contain_neutron_config('DEFAULT/nova_admin_username')
            is_expected.not_to contain_neutron_config('DEFAULT/nova_admin_password')
            is_expected.not_to contain_neutron_config('DEFAULT/nova_admin_password')
            is_expected.not_to contain_neutron_config('DEFAULT/nova_admin_tenant_id')
        end

        context 'when overriding parameters' do
            before :each do
                params.merge!(
                    :notify_nova_on_port_status_changes => false,
                    :notify_nova_on_port_data_changes   => false,
                    :send_events_interval               => '10',
                    :nova_url                           => 'http://nova:8774/v3',
                    :auth_url                           => 'http://keystone:35357/v2.0',
                    :auth_plugin                        => 'v2.password',
                    :username                           => 'joe',
                    :region_name                        => 'MyRegion',
                    :tenant_id                          => 'UUID2'
                )
            end
            it 'should configure neutron server with overrided parameters' do
                is_expected.to contain_neutron_config('DEFAULT/notify_nova_on_port_status_changes').with_value(false)
                is_expected.to contain_neutron_config('DEFAULT/notify_nova_on_port_data_changes').with_value(false)
                is_expected.to contain_neutron_config('DEFAULT/send_events_interval').with_value('10')
                is_expected.to contain_neutron_config('DEFAULT/nova_url').with_value('http://nova:8774/v3')
                is_expected.to contain_neutron_config('nova/auth_url').with_value('http://keystone:35357/v2.0')
                is_expected.to contain_neutron_config('nova/auth_plugin').with_value('v2.password')
                is_expected.to contain_neutron_config('nova/username').with_value('joe')
                is_expected.to contain_neutron_config('nova/password').with_value('secrete')
                is_expected.to contain_neutron_config('nova/password').with_secret( true )
                is_expected.to contain_neutron_config('nova/region_name').with_value('MyRegion')
                is_expected.to contain_neutron_config('nova/tenant_id').with_value('UUID2')
            end
        end

        context 'when using deprecated parameters' do
            before :each do
                params.merge!(
                    :nova_admin_auth_url  => 'http://keystone:35357/v2.0',
                    :nova_admin_username  => 'joe',
                    :nova_admin_password  => 'secrete',
                    :nova_region_name     => 'MyRegion',
                    :nova_admin_tenant_id => 'UUID2',
                    :password             => false
                )
            end
            it 'should configure neutron server with deprecated parameters' do
                is_expected.to contain_neutron_config('DEFAULT/nova_admin_auth_url').with_value('http://keystone:35357/v2.0')
                is_expected.to contain_neutron_config('DEFAULT/nova_admin_username').with_value('joe')
                is_expected.to contain_neutron_config('DEFAULT/nova_admin_password').with_value('secrete')
                is_expected.to contain_neutron_config('DEFAULT/nova_admin_password').with_secret( true )
                is_expected.to contain_neutron_config('DEFAULT/nova_region_name').with_value('MyRegion')
                is_expected.to contain_neutron_config('DEFAULT/nova_admin_tenant_id').with_value('UUID2')
                is_expected.not_to contain_neutron_config('nova/auth_url')
                is_expected.not_to contain_neutron_config('nova/username')
                is_expected.not_to contain_neutron_config('nova/password')
                is_expected.not_to contain_neutron_config('nova/tenant_id')
            end
        end

        context 'when no nova_admin_password or password is specified' do
            before :each do
                params.merge!({
                  :nova_admin_password => false,
                  :password            => false })
            end

            it_raises 'a Puppet::Error', /nova_admin_password or password must be set./
        end

        context 'when no nova_admin_tenant_id and nova_admin_tenant_name specified' do
            before :each do
                params.merge!({
                  :nova_admin_tenant_name => false,
                  :nova_admin_tenant_id   => false,
                  :nova_admin_password    => 'secrete',
                })
            end

            it_raises 'a Puppet::Error', /You must provide either nova_admin_tenant_name or nova_admin_tenant_id./
        end

        context 'when no tenant_id and tenant_name specified' do
            before :each do
                params.merge!({
                  :tenant_name => false,
                  :tenant_id   => false,
                  :password    => 'secrete',
                })
            end

            it_raises 'a Puppet::Error', /You must provide either tenant_name or tenant_id./
        end

        context 'when providing a nova_tenant_name' do
            before :each do
                params.merge!({
                  :nova_admin_tenant_name => 'services',
                  :nova_admin_tenant_id   => false,
                  :nova_admin_password    => 'secrete',
                  :password               => false
                })
            end
            it 'should configure nova admin tenant id' do
              is_expected.to contain_nova_admin_tenant_id_setter('nova_admin_tenant_id').with(
                :ensure           => 'present',
                :tenant_name      => 'services',
                :auth_url         => 'http://127.0.0.1:35357/v2.0',
                :auth_password    => 'secrete',
                :auth_tenant_name => 'services'
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

        it_configures 'neutron server notifications'
    end

    context 'on RedHat platforms' do
        let :facts do
            default_facts.merge({ :osfamily => 'RedHat' })
        end

        let :platform_params do
            {}
        end

        it_configures 'neutron server notifications'
    end

end
