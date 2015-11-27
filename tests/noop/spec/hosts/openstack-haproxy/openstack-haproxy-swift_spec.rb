require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-swift.pp'

describe manifest do
  shared_examples 'catalog' do
    ironic_enabled = Noop.hiera_structure 'ironic/enabled'
    if ironic_enabled
      baremetal_virtual_ip = Noop.hiera_structure 'network_metadata/vips/baremetal/ipaddr'

      it 'should declare ::openstack::ha::swift class with baremetal_virtual_ip' do
        should contain_class('openstack::ha::swift').with(
          'baremetal_virtual_ip' => baremetal_virtual_ip,
        )
      end
      it 'should declare openstack::ha::haproxy_service with name swift-baremetal' do
          should contain_openstack__ha__haproxy_service('swift-baremetal').with(
            'order'               => '125',
            'public_virtual_ip'   => false,
            'internal_virtual_ip' => baremetal_virtual_ip
          )
      end
    end
  end # end of shared_examples
    test_ubuntu_and_centos manifest
end

