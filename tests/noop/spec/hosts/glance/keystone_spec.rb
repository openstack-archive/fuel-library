require 'spec_helper'
require 'shared-examples'
manifest = 'glance/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    public_vip          = Noop.hiera('public_vip')
    management_address  = Noop.hiera('management_vip')
    management_protocol = 'http'
    public_ssl          = Noop.hiera_structure('public_ssl/services')

    if public_ssl
      public_address  = Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = public_vip
      public_protocol = 'http'
    end

    auth_name           = Noop.hiera_structure('glance/auth_name', 'glance')
    password            = Noop.hiera_structure('glance/user_password')
    configure_endpoint  = Noop.hiera_structure('glance/configure_endpoint', true)
    configure_user      = Noop.hiera_structure('glance/configure_user', true)
    configure_user_role = Noop.hiera_structure('glance/configure_user_role', true)
    region              = Noop.hiera_structure('glance/region', 'RegionOne')
    service_name        = Noop.hiera_structure('glance/service_name', 'glance')
    public_url          = "#{public_protocol}://#{public_address}:9292"
    internal_url        = "#{management_protocol}://#{management_address}:9292"
    admin_url           = public_url

    it 'should declare glance::keystone::auth class correctly' do
      should contain_class('glance::keystone::auth').with(
        'auth_name'           => auth_name,
        'password'            => password,
        'configure_endpoint'  => configure_endpoint,
        'configure_user'      => configure_user,
        'configure_user_role' => configure_user_role,
        'service_name'        => service_name,
        'public_url'          => public_url,
        'admin_url'           => admin_url,
        'internal_url'        => internal_url,
        'region'              => region,
      )
    end
  end
  test_ubuntu_and_centos manifest
end
