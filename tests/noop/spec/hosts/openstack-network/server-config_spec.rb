require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-config.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_neutron')
      neutron_config      = Noop.hiera_hash 'neutron_config'
      service_endpoint    = Noop.hiera 'service_endpoint'
      management_vip      = Noop.hiera 'management_vip'
      nova_endpoint       = Noop.hiera_structure('nova_endpoint',management_vip )
      nova_url            = "http://#{nova_endpoint}:8774/v2"
      nova_admin_auth_url = "http://#{service_endpoint}:35357/v2.0/"

      it 'should declare neutron::server::notifications class' do
        should contain_class('neutron::server::notifications').with(
          'nova_url'    => nova_url,
          'auth_url'    => nova_admin_auth_url,
          'username'    => Noop.hiera_structure('nova/user', 'nova'),
          'password'    => Noop.hiera_structure('nova/user_password'),
          'tenant_name' => Noop.hiera_structure('nova/tenant', 'services'),
          'region_name' => Noop.hiera_structure('region', 'RegionOne'),
        )
      end
    end
  end #end of shared_examples
  test_ubuntu_and_centos manifest
end

