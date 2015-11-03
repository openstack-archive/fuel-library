require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/routers.pp'

describe manifest do
  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') == true and Noop.hiera('primary_controller'))
      context 'with Neutron' do
        neutron_config = Noop.hiera('neutron_config')
        nets = neutron_config['predefined_networks']

        floating_net   = (neutron_config['default_floating_net'] or 'net04_ext')
        private_net    = (neutron_config['default_private_net'] or 'net04')
        default_router = (neutron_config['default_router'] or 'router04')

        context 'Default router serves tenant networks' do
          it 'should be created and serve gateway' do
            should contain_neutron_router(default_router).with(
              'ensure'               => 'present',
              'gateway_network_name' => floating_net,
              'name'                 => default_router,
            )
          end
          it 'should serve private network' do
            should contain_neutron_router_interface("#{default_router}:#{private_net}__subnet").with(
              'ensure' => 'present',
             )
            should contain_neutron_router(default_router).that_comes_before(
              "Neutron_router_interface[#{default_router}:#{private_net}__subnet]"
            )
          end
        end

        context 'Default router serves Ironic baremetal network', :if => nets.has_key?('baremetal') do
          it 'should serve baremetal network' do
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
  end
  test_ubuntu_and_centos manifest
end
