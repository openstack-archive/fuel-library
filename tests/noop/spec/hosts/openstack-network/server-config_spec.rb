require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-config.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_neutron')
      neutron_config      = Noop.hiera_hash 'neutron_config'
      nova_hash           = Noop.hiera_hash 'nova'
      service_endpoint    = Noop.hiera 'service_endpoint'
      nova_endpoint       = Noop.hiera 'nova_endpoint'
      nova_url            = "http://#{nova_endpoint}:8774/v2"
      nova_admin_auth_url = "#{service_endpoint}:35357/v2.0"
      auth_region         = Noop.hiera 'region'

      it 'should declare neutron::service::notifications class' do
        should contain_class('neutron::service::notifications').with(
          'nova_url'    => nova_url,
          'auth_url'    => nova_admin_auth_url,
          'username'    => nova_hash['user'],
          'password'    => nova_hash['user_password'],
          'tenant_name' => nova_hash['tenant'],
          'auth_region' => auth_region,
        )
      end
    end
  end #end of shared_examples
  test_ubuntu_and_centos manifest
end

