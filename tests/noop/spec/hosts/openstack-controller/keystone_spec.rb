require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for nova auth' do
      contain_class('nova::keystone::auth')
    end

    if Noop.hiera_structure 'public_ssl/services'
      public_protocol = 'https'
    else
      public_protocol = 'http'
    end

    public_address   = Noop.hiera('public_vip')
    admin_address    = Noop.hiera('management_vip')

    public_url   = "#{public_protocol}://#{public_address}:8774/v2/%(tenant_id)s"
    admin_url    = "http://#{admin_address}:8774/v2/%(tenant_id)s"

    ec2_public_url   = "#{public_protocol}://#{public_address}:8773/services/Cloud"
    ec2_internal_url = "http://#{admin_address}:8773/services/Cloud"
    ec2_admin_url    = "http://#{admin_address}:8773/services/Admin"

    it 'class nova::keystone::auth should  contain correct *_url' do
      should contain_class('nova::keystone::auth').with('public_url' => public_url)
      should contain_class('nova::keystone::auth').with('admin_url' => admin_url)
      should contain_class('nova::keystone::auth').with('internal_url' => admin_url)
      should contain_class('nova::keystone::auth').with('ec2_public_url' => ec2_public_url)
      should contain_class('nova::keystone::auth').with('ec2_admin_url' => ec2_admin_url)
      should contain_class('nova::keystone::auth').with('ec2_internal_url' => ec2_internal_url)
    end
  end

  test_ubuntu_and_centos manifest
end
