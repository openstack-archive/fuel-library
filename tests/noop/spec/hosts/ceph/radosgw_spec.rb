require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:admin_auth_address) {
      Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin',
      'hostname',
        [Noop.hiera('service_endpoint', Noop.hiera('management_vip'))]
    }

    let(:admin_url) {
      "#{admin_auth_address}:35357"
    }

    if storage_hash['objects_ceph']
      rgw_id = 'radosgw.gateway'

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
    end
  end

  test_ubuntu_and_centos manifest
end

