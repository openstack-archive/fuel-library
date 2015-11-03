require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/common-config.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_neutron')
      context 'with Neutron' do
        neutron_config = Noop.hiera('neutron_config')
        # nets = neutron_config['predefined_networks']

        # floating_net   = (neutron_config['default_floating_net'] or 'net04_ext')
        # private_net    = (neutron_config['default_private_net'] or 'net04')
        # default_router = (neutron_config['default_router'] or 'router04')

        context 'Default router serves tenant networks' do
          it 'should be created and serve gateway' do
          end
        end
      end

      it 'should apply kernel tweaks for connections' do
        should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh1').with_value('1024')
        should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh2').with_value('2048')
        should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh3').with_value('4096')
      end

    end
  end
  test_ubuntu_and_centos manifest
end

