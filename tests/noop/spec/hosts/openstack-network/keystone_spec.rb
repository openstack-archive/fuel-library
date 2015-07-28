require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    public_vip = Noop.hiera('public_vip')
    public_ssl = Noop.hiera_structure('public_ssl/services', false)
    if public_ssl
      public_address  = Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = public_vip
      public_protocol = 'http'
    end
    auth_name           = Noop.hiera_structure('quantum_settings/auth_name', 'neutron')
    password            = Noop.hiera_structure('quantum_settings/keystone/admin_password')
    tenant              = Noop.hiera_structure('quantum_settings/tenant', 'services')
    region              = Noop.hiera_structure('quantum_settings/region', 'RegionOne')
    service_name        = Noop.hiera_structure('quantum_settings/service_name', 'neutron')
    admin_address       = Noop.hiera_structure('management_vip')
    configure_endpoint  = Noop.hiera_structure('quantum_settings/configure_endpoint', true)
    configure_user      = Noop.hiera_structure('quantum_settings/configure_user', true)
    configure_user_role = Noop.hiera_structure('quantum_settings/configure_user_role', true)
    internal_address    = admin_address

    it 'should declare neutron::keystone::auth class' do
      should contain_class('neutron::keystone::auth').with(
        'password'            => password,
        'auth_name'           => auth_name,
        'configure_endpoint'  => configure_endpoint,
        'configure_user'      => configure_user,
        'configure_user_role' => configure_user_role,
        'service_name'        => service_name,
        'public_address'      => public_address,
        'public_protocol'     => public_protocol,
        'admin_address'       => admin_address,
        'internal_address'    => internal_address,
        'region'              => region,
      )
    end
  end

  test_ubuntu_and_centos manifest
end
