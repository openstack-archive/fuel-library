require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/keystone.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do
    let(:public_vip) { task.hiera('public_vip') }
    let(:admin_address) { task.hiera('management_vip') }
    let(:public_ssl) { task.hiera_structure('public_ssl/services') }
    let(:public_ssl_hostname) { task.hiera_structure('public_ssl/hostname') }

    let(:api_bind_port) { '8386' }
    let(:public_protocol) { public_ssl ? 'https' : 'http' }
    let(:public_address) { public_ssl ? public_ssl_hostname : public_vip }

    let(:sahara_user) { task.hiera_structure('sahara_hash/user', 'sahara') }
    let(:sahara_password) { task.hiera_structure('sahara_hash/user_password') }
    let(:tenant) { task.hiera_structure('sahara_hash/tenant', 'services') }
    let(:region) { task.hiera_structure('sahara_hash/region', 'RegionOne') }
    let(:service_name) { task.hiera_structure('sahara_hash/service_name', 'sahara') }
    let(:public_url) { "#{public_protocol}://#{public_address}:#{api_bind_port}/v1.1/%(tenant_id)s" }
    let(:admin_url) { "http://#{admin_address}:#{api_bind_port}/v1.1/%(tenant_id)s" }

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[sahara::keystone::auth]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[sahara::keystone::auth]")
    end

    it 'should declare sahara::keystone::auth class correctly' do
      should contain_class('sahara::keystone::auth').with(
                 'auth_name' => sahara_user,
                 'password' => sahara_password,
                 'service_type' => 'data-processing',
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
