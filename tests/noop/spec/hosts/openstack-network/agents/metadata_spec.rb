# ROLE: primary-controller
# ROLE: controller
# ROLE: compute

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/metadata.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    let(:node_roles) do
      Noop.hiera('roles')
    end

    na_config                = Noop.hiera_hash('neutron_advanced_configuration', {})
    neutron_config           = Noop.hiera_hash('neutron_config')
    neutron_controller_roles = Noop.hiera('neutron_controller_nodes', ['neutron', 'primary-neutron'])
    neutron_compute_roles    = Noop.hiera('neutron_compute_nodes', ['compute'])
    workers_max              = Noop.hiera 'workers_max'
    isolated_metadata        = neutron_config.fetch('metadata',{}).fetch('isolated_metadata', true)
    ha_agent                 = na_config.fetch('dhcp_agent_ha', true)

    secret = neutron_config.fetch('metadata',{}).fetch('metadata_proxy_shared_secret')

    ssl_hash       = Noop.hiera_hash('use_ssl', {})
    management_vip = Noop.hiera('management_vip')
    nova_endpoint  = Noop.hiera('nova_endpoint', management_vip)
    nova_metadata_protocol = Noop.hiera('nova_metadata_protocol', 'http')
    let(:nova_internal_protocol) { Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'nova', 'internal', 'protocol', nova_metadata_protocol }
    let(:nova_internal_endpoint) { Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'nova', 'internal', 'hostname', nova_endpoint }

    if not (neutron_compute_roles & Noop.hiera('roles')).empty?
      context 'neutron-metadata-agent on compute' do
        na_config = Noop.hiera_hash('neutron_advanced_configuration')
        dvr = na_config.fetch('neutron_dvr', false)
        if dvr
          let(:metadata_workers) do
            facts[:os_workers] = 8
            neutron_config.fetch('workers', [facts[:os_workers].to_i/8+1, workers_max.to_i].min)
          end

          it { should contain_class('neutron::agents::metadata').with(
            'debug' => Noop.hiera('debug', true)
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'enabled' => true
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'manage_service' => true
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'metadata_ip' => nova_internal_endpoint
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'metadata_protocol' => nova_internal_protocol
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'shared_secret' => secret
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'metadata_workers' => metadata_workers
          )}

          include_examples 'override_resources'
        else
          it { should_not contain_class('neutron::agents::metadata') }
        end
        it { should_not contain_class('cluster::neutron::metadata') }
      end
    elsif not (neutron_controller_roles & Noop.hiera('roles')).empty?
      context 'with neutron-metadata-agent on controller' do

        let(:metadata_workers) do
          facts[:os_workers] = 8
          neutron_config.fetch('workers', [[facts[:os_workers].to_i, 2].max, workers_max.to_i].min)
        end

        it { should contain_class('neutron::agents::metadata').with(
          'debug' => Noop.hiera('debug', true)
        )}
        it { should contain_class('neutron::agents::metadata').with(
          'enabled' => true
        )}
        it { should contain_class('neutron::agents::metadata').with(
          'manage_service' => true
        )}
        it { should contain_class('neutron::agents::metadata').with(
          'metadata_ip' => nova_internal_endpoint
        )}
        it { should contain_class('neutron::agents::metadata').with(
          'metadata_protocol' => nova_internal_protocol
        )}
        it { should contain_class('neutron::agents::metadata').with(
          'shared_secret' => secret
        )}
        it { should contain_class('neutron::agents::metadata').with(
          'metadata_workers' => metadata_workers
        )}
        include_examples 'override_resources'
        if ha_agent
          it { should contain_class('cluster::neutron::metadata').with(
            'primary' => (node_roles.include? 'primary-neutron')
          )}
        else
          it { should_not contain_class('cluster::neutron::metadata') }
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
