require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-radosgw.pp'

describe manifest do
  shared_examples 'catalog' do
    images_ceph = Noop.hiera_structure 'storage/images_ceph'
    objects_ceph = Noop.hiera_structure 'storage/objects_ceph'
    if images_ceph and objects_ceph
      ironic_enabled = Noop.hiera_structure 'ironic/enabled'
      if ironic_enabled
        baremetal_virtual_ip = Noop.hiera_structure 'network_metadata/vips/baremetal/ipaddr'

        it 'should declare ::openstack::ha::radosgw class with baremetal_virtual_ip' do
          should contain_class('openstack::ha::radosgw').with(
            'baremetal_virtual_ip' => baremetal_virtual_ip,
          )
        end
        it 'should declare openstack::ha::haproxy_service with name radosgw-baremetal' do
            should contain_openstack__ha__haproxy_service('radosgw-baremetal').with(
              'order'               => '135',
              'public_virtual_ip'   => false,
              'internal_virtual_ip' => baremetal_virtual_ip
            )
        end
      end
    end
  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

