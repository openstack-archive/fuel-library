# ROLE: primary-controller
# ROLE: controller
# ROLE: compute

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/common-config.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_neutron')

      let(:network_scheme) do
        Noop.hiera_hash('network_scheme', {})
      end

      let(:prepare) do
        Noop.puppet_function('prepare_network_config', network_scheme)
      end

      let(:bind_host) do
        prepare
        Noop.puppet_function('get_network_role_property', 'neutron/api', 'ipaddr')
      end

      context 'with Neutron' do
        neutron_config = Noop.hiera('neutron_config')
        openstack_network_hash = Noop.hiera('openstack_network', {})
        adv_neutron_config = Noop.hiera_hash('neutron_advanced_configuration', {})
        enable_qos = adv_neutron_config.fetch('neutron_qos', false)
        service_plugins = [
          'neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',
          'neutron.services.metering.metering_plugin.MeteringPlugin',
        ]

        if enable_qos
          service_plugins.concat(['qos'])
        end

        it {
          verbose = openstack_network_hash['verbose']
          verbose = Noop.hiera('verbose', true) if verbose.nil?
          should contain_class('neutron').with('verbose' => verbose)
        }

        it {
          debug = openstack_network_hash['debug']
          debug = Noop.hiera('debug', true) if debug.nil?
          should contain_class('neutron').with('debug' => debug)
        }

        it { should contain_class('neutron').with('advertise_mtu' => 'true')}
        it { should contain_class('neutron').with('report_interval' => neutron_config['neutron_report_interval'])}
        it { should contain_class('neutron').with('dhcp_agents_per_network' => '2')}
        it { should contain_class('neutron').with('dhcp_lease_duration' => neutron_config['L3'].fetch('dhcp_lease_duration', '600')}
        it { should contain_class('neutron').with('mac_generation_retries' => '32')}
        it { should contain_class('neutron').with('allow_overlapping_ips' => 'true')}
        it { should contain_class('neutron').with('use_syslog' => Noop.hiera('use_syslog', true))}
        it { should contain_class('neutron').with('use_stderr' => Noop.hiera('use_stderr', false))}
        it { should contain_class('neutron').with('log_facility' => Noop.hiera('syslog_log_facility_neutron', 'LOG_LOCAL4'))}
        it { should contain_class('neutron').with('base_mac' => neutron_config['L2']['base_mac'])}
        it { should contain_class('neutron').with('core_plugin' => 'neutron.plugins.ml2.plugin.Ml2Plugin')}

        it { should contain_class('neutron').with('service_plugins' => service_plugins)}

        it { should contain_class('neutron').with('bind_host' => bind_host)}

        it {
          segmentation_type = neutron_config['L2']['segmentation_type']
          physical_net_mtu = 1500
          should contain_class('neutron').with('network_device_mtu' => physical_net_mtu)
        }

        it 'RMQ options' do
          rabbit_hash = Noop.hiera_hash('rabbit', {})
          should contain_class('neutron').with('rabbit_user' => rabbit_hash['user'])
          should contain_class('neutron').with('rabbit_password' => rabbit_hash['password'])
          should contain_class('neutron').with('rabbit_hosts' => Noop.hiera('amqp_hosts', '').split(','))
        end

        default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
        default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
        it 'should configure default_log_levels' do
          should contain_neutron_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
        end

      end

    end

    # equal for Nova-network and Neutron
    it 'should apply kernel tweaks for connections' do
      should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh1').with_value('4096')
      should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh2').with_value('8192')
      should contain_sysctl__value('net.ipv4.neigh.default.gc_thresh3').with_value('16384')
      should contain_sysctl__value('net.ipv4.ip_forward').with_value('1')
    end

    kombu_compression = Noop.hiera 'kombu_compression', ''

    if ['gzip', 'bz2'].include?(kombu_compression)
      it 'should configure kombu compression' do
        should contain_neutron_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
      end
    end

  end
  test_ubuntu_and_centos manifest
end

