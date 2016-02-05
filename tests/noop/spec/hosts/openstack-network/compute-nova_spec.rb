require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/compute-nova.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:nova_hash) do
      task.hiera_hash 'nova'
    end

    let(:nova_user_password) do
      nova_hash['user_password']
    end

    let(:network_scheme) do
      task.hiera_hash 'network_scheme'
    end

    let(:prepare_network_config) do
      task.puppet_function 'prepare_network_config', network_scheme
    end

    let(:bind_address) do
      task.puppet_function 'get_network_role_property', 'nova/api', 'ipaddr'
    end

    let(:nova_migration_ip) do
      task.puppet_function 'get_network_role_property', 'nova/migration', 'ipaddr'
    end

    let(:nova_rate_limits) do
      task.hiera_hash 'nova_rate_limits'
    end

    let(:public_interface) do
      task.puppet_function('get_network_role_property', 'public/vip', 'interface') || ''
    end

    let(:private_interface) do
      task.puppet_function 'get_network_role_property', 'nova/private', 'interface'
    end

    let(:fixed_network_range) do
      task.hiera 'fixed_network_range'
    end

    let(:network_size) do
      task.hiera 'network_size', nil
    end

    let(:num_networks) do
      task.hiera 'num_networks', nil
    end

    let(:network_config) do
      task.hiera('network_config', {})
    end

    let(:dns_nameservers) do
      task.hiera_array('dns_nameservers', [])
    end

    let(:use_vcenter) do
      task.hiera 'use_vcenter', false
    end

    if task.hiera('use_neutron') && task.hiera('role') == 'compute'
      context 'Neutron is used' do
        nova_hash = task.hiera_hash('nova')
        neutron_integration_bridge = 'br-int'
        libvirt_vif_driver = nova_hash.fetch('libvirt_vif_driver', 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver')
        neutron_config = task.hiera_hash('neutron_config')
        ks = neutron_config.fetch('keystone', {})
        management_vip     = task.hiera('management_vip')
        service_endpoint   = task.hiera('service_endpoint', management_vip)
        neutron_endpoint   = task.hiera('neutron_endpoint', management_vip)
        admin_password     = ks.fetch('admin_password')
        admin_tenant_name  = ks.fetch('admin_tenant', 'services')
        admin_username     = ks.fetch('admin_user', 'neutron')
        region_name        = task.hiera('region', 'RegionOne')
        auth_api_version   = 'v2.0'
        admin_identity_uri = "http://#{service_endpoint}:35357"
        admin_auth_url     = "#{admin_identity_uri}/#{auth_api_version}"
        neutron_url        = "http://#{neutron_endpoint}:9696"

        it { expect(subject).to contain_service('libvirt').with(
          :ensure   => 'running',
          :enable   => true,
          :name     => 'libvirtd'
        )}
        it { expect(subject).to contain_service('libvirt').that_notifies('Exec[destroy_libvirt_default_network]') }
        #
        it { expect(subject).to contain_exec('destroy_libvirt_default_network').with(
          :command => 'virsh net-destroy default',
          :onlyif  => 'virsh net-info default | grep -qE "Active:.* yes"',
          :tries   => 3,
        )}
        it { expect(subject).to contain_exec('destroy_libvirt_default_network').that_requires('Service[libvirt]')}
        #
        it { expect(subject).to contain_exec('undefine_libvirt_default_network').with(
          :command => 'virsh net-undefine default',
          :onlyif  => 'virsh net-info default 2>&1 > /dev/null',
          :tries   => 3,
        )}
        it { expect(subject).to contain_exec('undefine_libvirt_default_network').that_requires('Exec[destroy_libvirt_default_network]')}
        #
        it { expect(subject).to contain_file_line('clear_emulator_capabilities').with(
          :path    => '/etc/libvirt/qemu.conf',
          :line    => 'clear_emulator_capabilities = 0',
        )}
        it { expect(subject).to contain_file_line('clear_emulator_capabilities').that_notifies('Service[libvirt]') }
        #
        it { expect(subject).to contain_class('nova::compute::neutron').with(
          :libvirt_vif_driver => libvirt_vif_driver,
        )}
        #
        it { expect(subject).to contain_nova_config('DEFAULT/my_ip').with(
          :value => nova_migration_ip,
        )}
        #
        it { expect(subject).to contain_nova_config('DEFAULT/linuxnet_interface_driver').with(
          :value => 'nova.network.linux_net.LinuxOVSInterfaceDriver'
        )}
        it { expect(subject).to contain_nova_config('DEFAULT/linuxnet_interface_driver').that_notifies('Service[nova-compute]') }
        #
        it { expect(subject).to contain_nova_config('DEFAULT/linuxnet_ovs_integration_bridge').with(
          :value => neutron_integration_bridge
        )}
        it { expect(subject).to contain_nova_config('DEFAULT/linuxnet_ovs_integration_bridge').that_notifies('Service[nova-compute]') }
        #
        it { expect(subject).to contain_nova_config('DEFAULT/network_device_mtu').with(
          :value => '65000'
        )}
        it { expect(subject).to contain_nova_config('DEFAULT/network_device_mtu').that_notifies('Service[nova-compute]') }
        #
        it { expect(subject).to contain_class('nova::network::neutron').with(
          :neutron_admin_password    => admin_password,
          :neutron_admin_tenant_name => admin_tenant_name,
          :neutron_region_name       => region_name,
          :neutron_admin_username    => admin_username,
          :neutron_ovs_bridge        => neutron_integration_bridge,
        )}
        if task.hiera_structure('use_ssl', false)
          admin_identity_address = task.hiera_structure('use_ssl/keystone_admin_hostname')
          neutron_internal_address = task.hiera_structure('use_ssl/neutron_internal_hostname')
          it { expect(subject).to contain_class('nova::network::neutron').with(
            :neutron_admin_auth_url    => "https://#{admin_identity_address}:35357/v2.0",
            :neutron_url               => "https://#{neutron_internal_address}:9696",
          )}
        else
          it { expect(subject).to contain_class('nova::network::neutron').with(
            :neutron_admin_auth_url    => admin_auth_url,
            :neutron_url               => neutron_url,
          )}
        end
        #
        it { expect(subject).to contain_augeas('sysctl-net.bridge.bridge-nf-call-arptables').with(
          :context => '/files/etc/sysctl.conf',
          :changes => "set net.bridge.bridge-nf-call-arptables '1'",
        )}
        it { expect(subject).to contain_augeas('sysctl-net.bridge.bridge-nf-call-arptables').that_comes_before('Service[libvirt]')}
        #
        it { expect(subject).to contain_augeas('sysctl-net.bridge.bridge-nf-call-iptables').with(
          :context => '/files/etc/sysctl.conf',
          :changes => "set net.bridge.bridge-nf-call-iptables '1'",
        )}
        it { expect(subject).to contain_augeas('sysctl-net.bridge.bridge-nf-call-arptables').that_comes_before('Service[libvirt]')}
        #
        it { expect(subject).to contain_augeas('sysctl-net.bridge.bridge-nf-call-ip6tables').with(
          :context => '/files/etc/sysctl.conf',
          :changes => "set net.bridge.bridge-nf-call-ip6tables '1'",
        )}
        it { expect(subject).to contain_augeas('sysctl-net.bridge.bridge-nf-call-arptables').that_comes_before('Service[libvirt]')}
        #
        it { expect(subject).to contain_service('nova-compute').with(
          :ensure => 'running',
        )}
        #
        it { expect(subject).to contain_exec('wait-for-int-br').with(
          :command   => "ovs-vsctl br-exists #{neutron_integration_bridge}",
          :try_sleep => 6,
          :tries     => 10,
        )}
        it { expect(subject).to contain_exec('wait-for-int-br').that_comes_before('Service[nova-compute]') }
        #
      end
    elsif !task.hiera('use_neutron') && task.hiera('role') == 'compute'
      context 'Nova-network is used' do
        it { expect(subject).to contain_nova_config('DEFAULT/multi_host').with(
          :value => true
        )}
        it {expect(subject).to contain_nova_config('DEFAULT/send_arp_for_ha').with(
          :value => 'True'
        )}

        #it { expect(subject).to contain_nova_config('DEFAULT/metadata_host').with(:value  => bind_address) }

        it { expect(subject).to contain_class('Nova::Api').with(
                                 :ensure_package => "installed",
                                 :enabled => true,
                                 :admin_tenant_name => "services",
                                 :admin_user => "nova",
                                 :admin_password => nova_user_password,
                                 :enabled_apis => "metadata",
                                 :api_bind_address => bind_address,
                                 :ratelimits => nova_rate_limits,
        )}

        it {
          expect(subject).to contain_nova_config('DEFAULT/force_snat_range').with(:value => '0.0.0.0/0')
        }

        it do
          expect(subject).to contain_class('Nova::Network').with(
                                 :ensure_package => "installed",
                                 :public_interface => public_interface,
                                 :private_interface => private_interface,
                                 :fixed_range => fixed_network_range,
                                 :floating_range => false,
                                 :network_manager => "nova.network.manager.FlatDHCPManager",
                                 :config_overrides => network_config,
                                 :create_networks => true,
                                 :num_networks => num_networks,
                                 :network_size => network_size,
                                 :dns1 => dns_nameservers[0],
                                 :dns2 => dns_nameservers[1],
                                 :enabled => true,
                                 :install_service => true,
          )
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end

