require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/routers.pp'

describe manifest do
  shared_examples 'catalog' do
    context 'with Neutron', :if => (Noop.hiera('use_neutron') and Noop.hiera('primary_controller')) do
      neutron_config = Noop.hiera('neutron_config')
      nets = neutron_config['predefined_networks']

      floating_net   = (neutron_config['default_floating_net'] or 'net04_ext')
      private_net    = (neutron_config['default_private_net'] or 'net04')
      default_router = (neutron_config['default_router'] or 'router04')

      context 'Default router' do
        it 'should be created' do
          should contain_neutron_router(default_router).with(
            'ensure'               => 'present',
            'gateway_network_name' => floating_net,
            'name'                 => default_router,
          )
        end
        it 'should serve private network subnet' do
          should contain_neutron_router_interface("#{default_router}:#{private_net}__subnet").with(
            'ensure' => 'present',
           )
          should contain_neutron_router(default_router).that_comes_before(
            "Neutron_router_interface[#{default_router}:#{private_net}__subnet]"
          )
        end
      end

      context 'Ironic baremetal network', :if => nets.has_key?('baremetal') do
        it 'router should serve baremetal network_subnet' do
          should contain_neutron_router_interface("#{default_router}:baremetal__subnet").with(
            'ensure' => 'present',
          )
          should contain_neutron_router(default_router).that_comes_before(
            "Neutron_router_interface[#{default_router}:baremetal__subnet]"
          )
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
