require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for cinder auth' do
      contain_class('cinder::keystone::auth')
    end

    public_vip = Noop.hiera('public_vip')
    public_ssl = Noop.hiera_structure('public_ssl/services')

    if public_ssl
      public_address  = Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = public_vip
      public_protocol = 'http'
    end

    admin_address    = Noop.hiera('management_vip')
    internal_address = admin_address

    public_url   = "#{public_protocol}://#{public_address}:8776/v1/%(tenant_id)s"
    admin_url    = "http://#{admin_address}:8776/v1/%(tenant_id)s"
    internal_url = "http://#{internal_address}:8776/v1/%(tenant_id)s"

    public_url_v2   = "#{public_protocol}://#{public_address}:8776/v2/%(tenant_id)s"
    internal_url_v2 = "http://#{internal_address}:8776/v2/%(tenant_id)s"
    admin_url_v2    = "http://#{admin_address}:8776/v2/%(tenant_id)s"

    it 'class cinder::keystone::auth should  contain correct *_url' do
      should contain_class('cinder::keystone::auth').with('public_url' => public_url)
      should contain_class('cinder::keystone::auth').with('admin_url' => admin_url)
      should contain_class('cinder::keystone::auth').with('internal_url' => internal_url)
      should contain_class('cinder::keystone::auth').with('public_url_v2' => public_url_v2)
      should contain_class('cinder::keystone::auth').with('admin_url_v2' => admin_url_v2)
      should contain_class('cinder::keystone::auth').with('internal_url_v2' => internal_url_v2)
    end

  end #shared manifests

  test_ubuntu_and_centos manifest
end
