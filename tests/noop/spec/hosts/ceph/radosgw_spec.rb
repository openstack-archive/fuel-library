require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera 'storage'
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'

    if storage_hash['objects_ceph']
      it { should contain_class('ceph::radosgw').with(
           'primary_mon'     => ceph_monitor_nodes.keys[0],
           )
        }

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

