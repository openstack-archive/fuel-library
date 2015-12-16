# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do

    radosgw_enabled   = Noop.hiera_structure('storage/objects_ceph', false)
    ssl_hash          = Noop.hiera_structure('use_ssl', {})
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

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:service_endpoint) {
      Noop.hiera_structure 'service_endpoint'
    }

    let(:admin_identity_protocol) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone',
        'admin','protocol','http'
    }

    let(:admin_identity_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin',
      'hostname',
        [Noop.hiera('service_endpoint', Noop.hiera('management_vip'))]
    }

    let(:admin_identity_url) {
      "#{admin_identity_protocol}://#{admin_identity_address}:35357"
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
          'rgw_keystone_url' => admin_identity_url,
        )
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

