require 'spec_helper'
require 'shared-examples'
manifest = 'swift/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should set empty trusts_delegated_roles for swift auth' do
      contain_class('swift::keystone::auth')
    end

    swift                = Noop.hiera_structure('swift')
    public_ssl           = Noop.hiera_structure('public_ssl/services')
    public_address       = false

    if swift['management_vip']
      admin_address      = swift['management_vip']
    else
      admin_address      = Noop.hiera('management_vip')
    end

    if swift['public_vip']
      public_address     = swift['public_vip']
    end

    if public_ssl
      public_address  = public_address || Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = Noop.hiera('public_vip')
      public_protocol = 'http'
    end

    public_url          = "#{public_protocol}://#{public_address}:8080/v1/AUTH_%(tenant_id)s"
    admin_url           = "http://#{admin_address}:8080/v1/AUTH_%(tenant_id)s"

    public_url_s3       = "#{public_protocol}://#{public_address}:8080"
    admin_url_s3        = "http://#{admin_address}:8080"

    it 'class swift::keystone::auth should contain correct *_url' do
      should contain_class('swift::keystone::auth').with('public_url' => public_url)
      should contain_class('swift::keystone::auth').with('admin_url' => admin_url)
      should contain_class('swift::keystone::auth').with('internal_url' => admin_url)
    end

    it 'class swift::keystone::auth should contain correct S3 endpoints' do
      should contain_class('swift::keystone::auth').with('public_url_s3' => public_url_s3)
      should contain_class('swift::keystone::auth').with('admin_url_s3' => admin_url_s3)
      should contain_class('swift::keystone::auth').with('internal_url_s3' => admin_url_s3)
    end
  end

  test_ubuntu_and_centos manifest
end
