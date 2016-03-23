require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
<<<<<<< HEAD
    storage_hash = Noop.hiera_hash 'storage'
=======

    storage_hash = Noop.hiera 'storage'
>>>>>>> 5744cfa... Moving to upstream ceph
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'
    public_ssl_hash = Noop.hiera_hash('public_ssl')

    rgw_large_pool_name = '.rgw'
    rgw_large_pool_pg_nums = storage_hash['per_pool_pg_nums'][rgw_large_pool_name]
    gateway_name = 'radosgw.gateway'
    rgw_id = 'radosgw.gateway'
    radosgw_auth_key = "client.#{rgw_id}"
    rgw_s3_auth_use_keystone = Noop.hiera 'rgw_s3_auth_use_keystone', true

    let(:fsid) do
      Noop.hiera_structure 'storage/fsid', '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'
    end

    let(:radosgw_key) do
      Noop.hiera_structure 'storage/radosgw_key', 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
    end

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:service_endpoint) do
      Noop.hiera 'service_endpoint'
    end

    let(:internal_auth_protocol) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone',
        'internal','protocol','http'
    }

    let(:internal_auth_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone',
        'internal','hostname',
        [Noop.hiera('service_endpoint', Noop.hiera('management_vip'))]
    }

    let(:admin_auth_protocol) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone',
        'admin','protocol','http'
    }

    let(:admin_auth_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin',
      'hostname',
        [Noop.hiera('service_endpoint', Noop.hiera('management_vip'))]
    }

    let(:internal_url) {
      "#{internal_auth_protocol}://#{internal_auth_address}:5000"
    }

    let(:admin_url) {
      "#{admin_auth_protocol}://#{admin_auth_address}:35357"
    }

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'])
      it 'should configure apache mods' do
        should contain_apache__mod('proxy_fcgi')
      end

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
        should contain_ceph__rgw(gateway_name)
      end

#<<<<<<< HEAD
#      it 'should have explicit ordering between LB classes and particular actions' do
#        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]", "Class[ceph::keystone]")
#        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]", "Class[ceph::keystone]")
#      end

#      it { should contain_service('httpd').with(
#          :hasrestart => true,
#          :restart    => 'sleep 30 && apachectl graceful || apachectl restart',
#        )
#      }
#=======
#      it 'should contain ceph::rgw::keystone' do
#        should contain_ceph__rgw__keystone(gateway_name).with(
#          'rgw_keystone_url' => "#{service_endpoint}:35357",
#        )
#      end
#>>>>>>> 6ccbde6... [WIP] Moving to upstream ceph

      it { should contain_exec("Create #{rgw_large_pool_name} pool").with(
           :command => "ceph -n #{radosgw_auth_key} osd pool create #{rgw_large_pool_name} #{rgw_large_pool_pg_nums} #{rgw_large_pool_pg_nums}",
           :unless  => "rados lspools | grep '^#{rgw_large_pool_name}$'"
         )
      }

      it {
        if Noop.hiera('external_lb', false)
          url = "#{internal_url}/v3"
          provider = 'http'
        else
          url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
          provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
        end
        should contain_haproxy_backend_status('keystone-public').with(
          :url      => url,
          :provider => provider
        )
      }

      it {
        if Noop.hiera('external_lb', false)
          url = "#{admin_url}/v3"
          provider = 'http'
        else
          url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
          provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
        end
        should contain_haproxy_backend_status('keystone-admin').with(
          :url      => url,
          :provider => provider
        )
      }

    end
  end

  test_ubuntu_and_centos manifest
end

