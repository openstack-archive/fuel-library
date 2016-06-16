require 'spec_helper'
require 'shared-examples'
manifest = 'swift/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera_hash('storage')

    if !storage_hash['objects_ceph']
      it 'should set empty trusts_delegated_roles for swift auth' do
        contain_class('swift::keystone::auth')
      end

      public_vip           = Noop.hiera('public_vip')
      admin_address        = Noop.hiera('management_vip')
      public_ssl           = Noop.hiera_structure('public_ssl/services')

      if public_ssl
        public_address  = Noop.hiera_structure('public_ssl/hostname')
        public_protocol = 'https'
      else
        public_address  = public_vip
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
  end

  test_ubuntu_and_centos manifest
end
