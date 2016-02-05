require 'spec_helper'
require 'shared-examples'
manifest = 'glance/keystone.pp'

describe manifest do
  shared_examples 'catalog' do

    internal_protocol = 'http'
    internal_address = task.hiera('management_vip')
    admin_protocol = 'http'
    admin_address = internal_address

    if task.hiera_structure('use_ssl', false)
      public_protocol   = 'https'
      public_address    = task.hiera_structure('use_ssl/glance_public_hostname')
      internal_protocol = 'https'
      internal_address  = task.hiera_structure('use_ssl/glance_internal_hostname')
      admin_protocol    = 'https'
      admin_address     = task.hiera_structure('use_ssl/glance_admin_hostname')
    elsif task.hiera_structure('public_ssl/services')
      public_address  = task.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = task.hiera('public_vip')
      public_protocol = 'http'
    end

    auth_name           = task.hiera_structure('glance/auth_name', 'glance')
    password            = task.hiera_structure('glance/user_password')
    configure_endpoint  = task.hiera_structure('glance/configure_endpoint', true)
    configure_user      = task.hiera_structure('glance/configure_user', true)
    configure_user_role = task.hiera_structure('glance/configure_user_role', true)
    region              = task.hiera_structure('glance/region', 'RegionOne')
    tenant              = task.hiera_structure('glance/tenant', 'services') 
    service_name        = task.hiera_structure('glance/service_name', 'glance')
    public_url          = "#{public_protocol}://#{public_address}:9292"
    internal_url        = "#{internal_protocol}://#{internal_address}:9292"
    admin_url           = "#{admin_protocol}://#{admin_address}:9292"

    it 'should declare glance::keystone::auth class correctly' do
      should contain_class('glance::keystone::auth').with(
        'auth_name'           => auth_name,
        'password'            => password,
        'configure_endpoint'  => configure_endpoint,
        'configure_user'      => configure_user,
        'configure_user_role' => configure_user_role,
        'service_name'        => service_name,
        'public_url'          => public_url,
        'internal_url'        => internal_url,
        'admin_url'           => admin_url,
        'region'              => region,
        'tenant'              => tenant,
      )
    end
  end
  test_ubuntu_and_centos manifest
end
