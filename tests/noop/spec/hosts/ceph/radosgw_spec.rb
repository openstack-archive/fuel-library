require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do

    radosgw_enabled   = Noop.hiera_structure('storage/objects_ceph', false)
    region            = Noop.hiera('region', 'RegionOne')
    ssl_hash          = Noop.hiera_structure('use_ssl', {})
    public_ssl_hash   = Noop.hiera_structure('public_ssl', {})
    storage_hash      = Noop.hiera_hash 'storage'

    rgw_large_pool_name    = '.rgw'
    rgw_large_pool_pg_nums = storage_hash['per_pool_pg_nums'][rgw_large_pool_name]
    rgw_id                 = 'radosgw.gateway'
    radosgw_auth_key       = "client.#{rgw_id}"

    let(:gateway_name) {
      'radosgw.gateway'
    }

    let(:fsid) {
      Noop.hiera_structure 'storage/fsid', '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'
    }

    let(:internal_protocol) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'radosgw',
        'internal','protocol','http'
    }

    let(:internal_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'radosgw',
        'internal','hostname', [Noop.hiera('management_vip')]
    }

    let(:admin_protocol) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'radosgw',
        'admin','protocol','http'
    }

    let(:admin_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'radosgw','admin',
        'hostname', [Noop.hiera('management_vip')]
    }

    let(:public_protocol) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'radosgw',
        'public','protocol','http'
    }

    let(:public_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'radosgw','public',
        'hostname', [Noop.hiera('public_vip')]
    }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:admin_auth_protocol) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone',
        'admin','protocol','http'
    }

    let(:admin_auth_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin',
      'hostname',
        [Noop.hiera('service_endpoint', Noop.hiera('management_vip'))]
    }

    let(:admin_url) {
      "#{admin_auth_protocol}://#{admin_auth_address}:35357"
    }

    let(:radosgw_key) do
      Noop.hiera_structure 'storage/radosgw_key', 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
    end

    if radosgw_enabled
      it 'should add radosgw key' do
        should contain_ceph__key("client.#{gateway_name}").with(
          'secret'       => radosgw_key,
          'cap_mon'      => 'allow rw',
          'cap_osd'      => 'allow rwx',
          'inject'       => true,
        )
      end

      it 'should deploy ceph' do
        should contain_class('ceph').with(
          'fsid' => fsid,
        )
      end   

      it 'should contain ceph::rgw' do
        should contain_ceph__rgw(gateway_name).with(
          'frontend_type' => 'apache-proxy-fcgi',
        )
      end


      it 'should configure radosgw keystone' do
        should contain_ceph__rgw__keystone(gateway_name).with(
          'rgw_keystone_url' => admin_url,
        )
      end

      it 'should configure radosgw keystone endpoint' do
        should contain_keystone__resource__service_identity('radosgw').with(
          'configure_user'      => false,
          'configure_user_role' => false,
          'service_type'        => 'object-store',
          'service_description' => 'Openstack Object-Store Service',
          'service_name'        => 'swift',
          'region'              => region,
          'public_url'          => "#{public_protocol}://#{public_address}:8080/swift/v1",
          'admin_url'           => "#{internal_protocol}://#{internal_address}:8080/swift/v1",
          'internal_url'        => "#{admin_protocol}://#{admin_address}:8080/swift/v1",
        )
      end

      it 'should have explicit ordering between LB classes and particular actions' do
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Keystone::Resource::Service_identity[radosgw]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Keystone::Resource::Service_identity[radosgw]")
      end

      it { should contain_exec("Create #{rgw_large_pool_name} pool").with(
           :command => "ceph -n #{radosgw_auth_key} osd pool create #{rgw_large_pool_name} #{rgw_large_pool_pg_nums} #{rgw_large_pool_pg_nums}",
           :unless  => "rados lspools | grep '^#{rgw_large_pool_name}$'"
         )
      }

    end
  end

  test_ubuntu_and_centos manifest
end

