require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/keystone.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:public_vip) { Noop.hiera('public_vip') }
    let(:admin_address) { Noop.hiera('management_vip') }
    let(:public_ssl) { Noop.hiera_structure('public_ssl/services') }
    let(:public_ssl_hostname) { Noop.hiera_structure('public_ssl/hostname') }

    let(:api_bind_port) { '8386' }
    let(:public_protocol) { public_ssl ? 'https' : 'http' }
    let(:public_address) { public_ssl ? public_ssl_hostname : public_vip }

    let(:sahara_user) { Noop.hiera_structure('sahara_hash/user', 'sahara') }
    let(:sahara_password) { Noop.hiera_structure('sahara_hash/user_password') }
    let(:tenant) { Noop.hiera_structure('sahara_hash/tenant', 'services') }
    let(:region) { Noop.hiera_structure('sahara_hash/region', 'RegionOne') }
    let(:service_name) { Noop.hiera_structure('sahara_hash/service_name', 'sahara') }
    let(:public_url) { "#{public_protocol}://#{public_address}:#{api_bind_port}/v1.1/%(tenant_id)s" }
    let(:admin_url) { "http://#{admin_address}:#{api_bind_port}/v1.1/%(tenant_id)s" }

    it 'should declare sahara::keystone::auth class correctly' do
      should contain_class('sahara::keystone::auth').with(
                 'auth_name' => sahara_user,
                 'password' => sahara_password,
                 'service_type' => 'data_processing',
                 'service_name' => service_name,
                 'region' => region,
                 'tenant' => tenant,
                 'public_url' => public_url,
                 'admin_url' => admin_url,
                 'internal_url' => admin_url
             )
    end
  end
  test_ubuntu_and_centos manifest
end
