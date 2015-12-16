require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'] or storage_hash['objects_ceph'])
      rgw_id = 'radosgw.gateway'
      rgw_s3_auth_use_keystone = Noop.hiera 'rgw_s3_auth_use_keystone', true

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

    end
  end

  test_ubuntu_and_centos manifest
end

