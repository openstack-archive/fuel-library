# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu

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

    let(:sahara_user) { Noop.hiera_structure('sahara/user', 'sahara') }
    let(:sahara_password) { Noop.hiera_structure('sahara/user_password') }
    let(:tenant) { Noop.hiera_structure('sahara/tenant', 'services') }
    let(:region) { Noop.hiera_structure('sahara/region', 'RegionOne') }
    let(:service_name) { Noop.hiera_structure('sahara/service_name', 'sahara') }
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
