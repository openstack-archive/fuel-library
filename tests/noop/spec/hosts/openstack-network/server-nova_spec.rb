# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-nova.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_neutron') && Noop.hiera('role') =~ /controller/
      context 'setup Nova on controller for using Neutron' do
        na_config = Noop.hiera_hash('neutron_advanced_configuration')
        neutron_config = Noop.hiera_hash('neutron_config')

        floating_net = neutron_config.fetch('default_floating_net', 'net04_ext')
        ks  = neutron_config.fetch('keystone', {})
        admin_password     = ks.fetch('admin_password')
        admin_tenant_name  = ks.fetch('admin_tenant', 'services')
        admin_username     = ks.fetch('admin_user', 'neutron')
        region_name        = Noop.hiera('region', 'RegionOne')
        management_vip     = Noop.hiera('management_vip')
        service_endpoint   = Noop.hiera('service_endpoint', management_vip)
        neutron_endpoint   = Noop.hiera('neutron_endpoint', management_vip)
        auth_api_version   = 'v3'
        admin_identity_uri = "http://#{service_endpoint}:35357"
        admin_auth_url     = "#{admin_identity_uri}/#{auth_api_version}"
        neutron_url        = "http://#{neutron_endpoint}:9696"
        it { should contain_service('nova-api').with(
          'ensure' => 'running'
        )}
        it { should contain_nova_config('DEFAULT/default_floating_pool').with(
          'value' => floating_net
        ).that_notifies('Service[nova-api]')}
        it { should contain_class('nova::network::neutron').with(
          'neutron_password' => admin_password
        )}
        it { should contain_class('nova::network::neutron').with(
          'neutron_project_name' => admin_tenant_name
        )}
        it { should contain_class('nova::network::neutron').with(
          'neutron_region_name' => region_name
        )}
        it { should contain_class('nova::network::neutron').with(
          'neutron_username' => admin_username
        )}
        it { should contain_class('nova::network::neutron').with(
          'neutron_ovs_bridge' => 'br-int'
        )}

        if Noop.hiera_structure('use_ssl', false)
          context 'with overridden TLS' do
            admin_auth_protocol = 'https'
            admin_auth_endpoint = Noop.hiera_structure('use_ssl/keystone_admin_hostname')
            it { should contain_class('nova::network::neutron').with(
              'neutron_auth_url' => "#{admin_auth_protocol}://#{admin_auth_endpoint}:35357/#{auth_api_version}"
            )}

            neutron_internal_protocol = 'https'
            neutron_internal_endpoint = Noop.hiera_structure('use_ssl/neutron_internal_hostname')
            it { should contain_class('nova::network::neutron').with(
              'neutron_url' => "#{neutron_internal_protocol}://#{neutron_internal_endpoint}:9696"
            )}
          end
        else
          context 'without overridden TLS' do
            it { should contain_class('nova::network::neutron').with(
              'neutron_auth_url' => admin_auth_url
            )}
            it { should contain_class('nova::network::neutron').with(
              'neutron_url' => neutron_url
            )}
          end
        end
      end

    elsif !Noop.hiera('use_neutron') && Noop.hiera('role') =~ /controller/
      context 'setup Nova on controller for using nova-network' do

        private_interface  = Noop.hiera('private_int')
        public_interface   = Noop.hiera('public_int')
        fixed_range        = Noop.hiera('fixed_network_range')
        network_manager    = Noop.hiera('network_manager')
        network_config     = Noop.hiera_hash('network_config', {})
        num_networks       = Noop.hiera('num_networks')
        network_size       = Noop.hiera('network_size')
        nameservers        = Noop.hiera_array('dns_nameservers', [])
        primary_controller = Noop.hiera('primary_controller', false)

        if nameservers
          if nameservers.size >= 2
            dns_opts = "--dns1 #{nameservers[0]} --dns2 #{nameservers[1]}"
          else
            dns_opts = "--dns1 #{nameservers[0]}"
          end
        else
          dns_opts = ""
        end

        it { should contain_nova_config('DEFAULT/force_snat_range').with(
          'value' => '0.0.0.0/0'
        )}
        it { should contain_class('nova::network').with(
          'ensure_package' => 'installed'
        )}
        it { should contain_class('nova::network').with(
          'enabled' => false
        )}
        it { should contain_class('nova::network').with(
          'create_networks' => false
        )}
        it { should contain_class('nova::network').with(
          'floating_range' => false
        )}
        it { should contain_class('nova::network').with(
          'private_interface' => private_interface
        )}
        it { should contain_class('nova::network').with(
          'public_interface' => '' # because controller
        )}
        it { should contain_class('nova::network').with(
          'fixed_range' => fixed_range
        )}
        it { should contain_class('nova::network').with(
          'network_manager' => network_manager
        )}
        it { should contain_class('nova::network').with(
          'config_overrides' => network_config
        )}
        it { should contain_class('nova::network').with(
          'num_networks' => num_networks
        )}
        it { should contain_class('nova::network').with(
          'network_size' => network_size
        )}
        it { should contain_class('nova::network').with(
          'dns1' => nameservers[0]
        )}
        it { should contain_class('nova::network').with(
          'dns2' => nameservers[1]
        )}

        if primary_controller
          it 'should create private nova network' do
            should contain_exec('create_private_nova_network').with(
              'command' => "nova-manage network create novanetwork #{fixed_range} #{num_networks} #{network_size} #{dns_opts}"
            )
          end
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
