require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'] or storage_hash['objects_ceph'])
      it { should contain_class('ceph::radosgw').with(
           'primary_mon'   => ceph_monitor_nodes.keys[0],
           'rgw_frontends' => 'fastcgi socket_port=9000 socket_host=127.0.0.1',
           )
        }

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

