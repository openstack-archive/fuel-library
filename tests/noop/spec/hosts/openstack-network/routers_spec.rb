# HIERA: neut_tun.ceph.murano.sahara.ceil-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ironic-primary-controller
# HIERA: neut_tun.l3ha-primary-controller
# HIERA: neut_vlan.ceph-primary-controller
# HIERA: neut_vlan.dvr-primary-controller
# HIERA: neut_vlan.murano.sahara.ceil-controller
# HIERA: neut_vlan.murano.sahara.ceil-primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/routers.pp'

describe manifest do
  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') and Noop.hiera('primary_controller'))
      context 'with Neutron' do
        neutron_config = Noop.hiera('neutron_config')
        nets = neutron_config['predefined_networks']

        floating_net             = (neutron_config['default_floating_net'] or 'net04_ext')
        private_net              = (neutron_config['default_private_net'] or 'net04')
        default_router           = (neutron_config['default_router'] or 'router04')
        baremetal_router         = (neutron_config['baremetal_router'] or 'baremetal')
        l3_ha                    = Noop.hiera_hash('neutron_advanced_configuration', {}).fetch('neutron_l3_ha', false)
        dvr                      = Noop.hiera_hash('neutron_advanced_configuration', {}).fetch('neutron_dvr', false)
        network_metadata         = Noop.hiera_hash('network_metadata')
        neutron_controller_roles = Noop.hiera('neutron_controller_nodes', ['controller', 'primary-controller'])
        neutron_controller_nodes = Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, neutron_controller_roles
        neutron_controllers_num  = neutron_controller_nodes.size

        if (neutron_controllers_num < 2 and l3_ha)
          context 'With L3 HA and not enough number of controllers' do
            it 'should not create a default router' do
              should_not contain_neutron_router(default_router)
            end
            it 'should not serve private network' do
              should_not contain_neutron_router_interface("#{default_router}:#{private_net}__subnet")
            end
            it 'should not serve baremetal network' do
              should_not contain_neutron_router_interface("#{default_router}:baremetal__subnet")
            end
          end
        else
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

          if dvr
            context 'Separate non-dvr router serves baremetal', :if => nets.has_key?('baremetal') do
              it 'should be created and serve gateway' do
                should contain_neutron_router(baremetal_router).with(
                  'ensure'               => 'present',
                  'gateway_network_name' => floating_net,
                  'name'                 => baremetal_router,
                  'distributed'          => false,
                )
              end
              it 'should serve baremetal network' do
                should contain_neutron_router_interface("#{baremetal_router}:baremetal__subnet").with(
                  'ensure' => 'present',
                )
                should contain_neutron_router(baremetal_router).that_comes_before(
                  "Neutron_router_interface[#{baremetal_router}:baremetal__subnet]"
                )
              end
            end
          else
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
    end
  end
  test_ubuntu_and_centos manifest
end
