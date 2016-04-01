# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu
# SKIP_HIERA: neut_vlan.ceph.ceil-primary-controller ubuntu FIXME
# SKIP_HIERA: neut_vlan_l3ha.ceph.ceil-controller ubuntu FIXME
# SKIP_HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu FIXME

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera_hash 'storage'
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'

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

    if storage_hash['objects_ceph']
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
           'rgw_frontends'    => 'fastcgi socket_port=9000 socket_host=127.0.0.1',
           'rgw_keystone_url' => admin_url,
           )
        }

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
    end
  end

  test_ubuntu_and_centos manifest
end

