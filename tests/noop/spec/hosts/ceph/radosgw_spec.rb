require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera_hash 'storage'
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'
    public_ssl_hash = Noop.hiera_hash('public_ssl')

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

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

    let(:public_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,public_ssl_hash,'radosgw',
      'public','hostname',
        [Noop.hiera('public_vip')]
     }

    let(:internal_url) {
      "#{internal_auth_protocol}://#{internal_auth_address}:5000"
    }

    let(:admin_url) {
      "#{admin_auth_protocol}://#{admin_auth_address}:35357"
    }

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'])
      rgw_large_pool_name = '.rgw'
      rgw_large_pool_pg_nums = storage_hash['per_pool_pg_nums'][rgw_large_pool_name]
      rgw_id = 'radosgw.gateway'
      radosgw_auth_key = "client.#{rgw_id}"

      it 'should configure apache mods' do
        if facts[:osfamily] == 'Debian'
          should contain_apache__mod('rewrite')
          should contain_apache__mod('proxy')
          should contain_apache__mod('proxy_fcgi')
        else
          should contain_apache__mod('rewrite')
          should_not contain_apache__mod('proxy')
          should_not contain_apache__mod('proxy_fcgi')
        end
      end

      it { should contain_class('ceph::radosgw').with(
           'primary_mon'   => ceph_monitor_nodes.keys[0],
           'rgw_frontends' => 'fastcgi socket_port=9000 socket_host=127.0.0.1',
           'pub_ip'        => public_address,
           )
        }

      it 'should have explicit ordering between LB classes and particular actions' do
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]", "Class[ceph::keystone]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]", "Class[ceph::keystone]")
      end

      it { should contain_service('httpd').with(
          :hasrestart => true,
          :restart    => 'sleep 30 && apachectl graceful || apachectl restart',
        )
      }

      it { should contain_exec("Create #{rgw_large_pool_name} pool").with(
           :command => "ceph -n #{radosgw_auth_key} osd pool create #{rgw_large_pool_name} #{rgw_large_pool_pg_nums} #{rgw_large_pool_pg_nums}",
           :unless  => "rados lspools | grep '^#{rgw_large_pool_name}$'"
         )
      }

      it {
        if Noop.hiera('external_lb', false)
          url = internal_url
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
          url = admin_url
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

