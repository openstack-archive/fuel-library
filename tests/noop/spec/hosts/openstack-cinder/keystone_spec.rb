require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for cinder auth' do
      contain_class('cinder::keystone::auth')
    end

  public_vip           = Noop.hiera('public_vip')
  public_ssl           = Noop.hiera_structure('public_ssl/services')

  if public_ssl
    public_address  = Noop.hiera_structure('public_ssl/hostname')
    public_protocol = 'https'
  else
    public_address  = public_vip
    public_protocol = 'http'
  end
  admin_address = Noop.hiera 'management_vip'

  password = Noop.hiera_structure 'cinder/user_password'
  auth_name = Noop.hiera_structure 'cinder/auth_name', 'cinder'
  configure_endpoint = Noop.hiera_structure 'cinder/configure_endpoint', true
  configure_user = Noop.hiera_structure 'cinder/configure_user_role', true
  service_name = Noop.hiera_structure 'cinder/service_name', 'cinder'
  region = Noop.hiera_structure 'cinder/region', 'RegionOne'

  it 'should declare cinder::keystone::auth class with propper parameters' do
    should contain_class('cinder::keystone::auth').with(
      'password'           => password,
      'auth_name'          => auth_name,
      'configure_endpoint' => configure_endpoint,
      'configure_user'     => configure_user,
      'service_name'       => service_name,
      'public_address'     => public_address,
      'public_protocol'    => public_protocol,
      'admin_address'      => admin_address,
      'internal_address'   => admin_address,
      'region'             => region,
    )
  end

  end #end of shared examples

  test_ubuntu_and_centos manifest
end
