require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'
    public_ssl_hash = Noop.hiera('public_ssl')

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

    let(:internal_url) {
      "#{internal_auth_protocol}://#{internal_auth_address}:5000"
    }

    let(:admin_url) {
      "#{admin_auth_protocol}://#{admin_auth_address}:35357"
    }

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'] or storage_hash['objects_ceph'])
      rgw_id = 'radosgw.gateway'
      rgw_s3_auth_use_keystone = Noop.hiera 'rgw_s3_auth_use_keystone', true

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
           )
        }

      it 'should configure s3 keystone authentication for RadosGW' do
        should contain_class('ceph::radosgw').with(
          :rgw_use_keystone => true,
        )
        should contain_ceph_conf("client.#{rgw_id}/rgw_s3_auth_use_keystone").with(
          :value => rgw_s3_auth_use_keystone,
        )
      end

      it { should contain_haproxy_backend_status('keystone-public').that_comes_before('Class[ceph::keystone]') }
      it { should contain_haproxy_backend_status('keystone-admin').that_comes_before('Class[ceph::keystone]') }
      it {
        should contain_service('httpd').with(
             'hasrestart' => true,
             'restart'    => 'sleep 30 && apachectl graceful || apachectl restart',
        )
      }

      it {
        if Noop.hiera('external_lb', false)
          url = internal_url
          provider = 'http'
        else
          url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
          provider = nil
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
          provider = nil
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

