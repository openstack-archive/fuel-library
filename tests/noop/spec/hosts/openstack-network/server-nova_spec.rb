# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-nova.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_neutron') && Noop.hiera('role') =~ /controller/
      context 'setup Nova on controller for using Neutron' do
        na_config = Noop.hiera_hash('neutron_advanced_configuration')
        neutron_config = Noop.hiera_hash('neutron_config')

        floating_net = neutron_config.fetch('default_floating_net', 'net04_ext')
        ks  = neutron_config.fetch('keystone', {})
        admin_password     = ks.fetch('admin_password')
        admin_tenant_name  = ks.fetch('admin_tenant', 'services')
        admin_username     = ks.fetch('admin_user', 'neutron')
        region_name        = Noop.hiera('region', 'RegionOne')
        management_vip     = Noop.hiera('management_vip')
        service_endpoint   = Noop.hiera('service_endpoint', management_vip)
        neutron_endpoint   = Noop.hiera('neutron_endpoint', management_vip)
        auth_api_version   = 'v3'
        admin_identity_uri = "http://#{service_endpoint}:35357"
        admin_auth_url     = "#{admin_identity_uri}/#{auth_api_version}"
        neutron_url        = "http://#{neutron_endpoint}:9696"
        it { should contain_service('nova-api').with(
          'ensure' => 'running'
        )}
        it { should contain_nova_config('DEFAULT/default_floating_pool').with(
          'value' => floating_net
        ).that_notifies('Service[nova-api]')}
        it { should contain_class('nova::network::neutron').with(
          'neutron_password' => admin_password
        )}
        it { should contain_class('nova::network::neutron').with(
          'neutron_project_name' => admin_tenant_name
        )}
        it { should contain_class('nova::network::neutron').with(
          'neutron_region_name' => region_name
        )}
        it { should contain_class('nova::network::neutron').with(
          'neutron_username' => admin_username
        )}
        it { should contain_class('nova::network::neutron').with(
          'neutron_ovs_bridge' => 'br-int'
        )}

        if Noop.hiera_structure('use_ssl', false)
          context 'with overridden TLS' do
            admin_auth_protocol = 'https'
            admin_auth_endpoint = Noop.hiera_structure('use_ssl/keystone_admin_hostname')
            it { should contain_class('nova::network::neutron').with(
              'neutron_auth_url' => "#{admin_auth_protocol}://#{admin_auth_endpoint}:35357/#{auth_api_version}"
            )}

            neutron_internal_protocol = 'https'
            neutron_internal_endpoint = Noop.hiera_structure('use_ssl/neutron_internal_hostname')
            it { should contain_class('nova::network::neutron').with(
              'neutron_url' => "#{neutron_internal_protocol}://#{neutron_internal_endpoint}:9696"
            )}
          end
        else
          context 'without overridden TLS' do
            it { should contain_class('nova::network::neutron').with(
              'neutron_auth_url' => admin_auth_url
            )}
            it { should contain_class('nova::network::neutron').with(
              'neutron_url' => neutron_url
            )}
          end
        end
      end

    end
  end
  test_ubuntu_and_centos manifest
end
