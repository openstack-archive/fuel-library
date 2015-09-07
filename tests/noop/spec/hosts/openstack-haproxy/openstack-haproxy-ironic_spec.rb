require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-ironic.pp'

ironic_enabled = Noop.hiera_structure 'ironic/enabled'
if ironic_enabled
  describe manifest do
    shared_examples 'catalog' do
      baremetal_virtual_ip = Noop.hiera_structure 'network_metadata/vips/baremetal/ipaddr'
      it 'should declare openstack::ha::ironic class with baremetal_virtual_ip' do
        should contain_class('openstack::ha::ironic').with(
          'baremetal_virtual_ip' => baremetal_virtual_ip,
        )
      end
    end # end of shared_examples
    test_ubuntu_and_centos manifest
  end
end # ironic
