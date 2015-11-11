require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/agents/metadata.pp'

describe manifest do
  shared_examples 'catalog' do
    if Noop.hiera('use_neutron')

      let(:node_role) do
        Noop.hiera('role')
      end

      na_config                = Noop.hiera_hash('neutron_advanced_configuration')
      neutron_config           = Noop.hiera_hash('neutron_config')
      neutron_controller_roles = Noop.hiera_hash('neutron_controller_nodes', ['controller', 'primary-controller'])
      isolated_metadata        = neutron_config.fetch('metadata',{}).fetch('isolated_metadata', true)
      ha_agent                 = na_config.fetch('dhcp_agent_ha', true)

      ks = neutron_config.fetch('keystone',{})
      ks_user = ks.fetch('admin_user', 'neutron')
      ks_tenant = ks.fetch('admin_tenant', 'services')
      ks_password = ks.fetch('admin_password')

      secret = neutron_config.fetch('metadata',{}).fetch('metadata_proxy_shared_secret')

      management_vip = Noop.hiera('management_vip')
      nova_endpoint  = Noop.hiera('nova_endpoint', management_vip)
      auth_region        = Noop.hiera('region', 'RegionOne')
      service_endpoint   = Noop.hiera('service_endpoint')
      auth_api_version   = 'v2.0'
      admin_identity_uri = "http://#{service_endpoint}:35357"
      admin_auth_url     = "#{admin_identity_uri}/#{auth_api_version}"

      if Noop.hiera('role') == 'compute'
        context 'neutron-metadata-agent on compute' do
          na_config = Noop.hiera_hash('neutron_advanced_configuration')
          dvr = na_config.fetch('neutron_dvr', false)
          if dvr
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
              'metadata_ip' => nova_endpoint
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'shared_secret' => secret
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'auth_region' => auth_region
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'auth_url' => admin_auth_url
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'auth_user' => ks_user
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'auth_tenant' => ks_tenant
            )}
            it { should contain_class('neutron::agents::metadata').with(
              'auth_password' => ks_password
            )}
          else
            it { should_not contain_class('neutron::agents::metadata') }
          end
          it { should_not contain_class('cluster::neutron::metadata') }
        end
      elsif neutron_controller_roles.include?(Noop.hiera('role'))
        context 'with neutron-metadata-agent on controller' do

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
            'metadata_ip' => nova_endpoint
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'shared_secret' => secret
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'auth_region' => auth_region
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'auth_url' => admin_auth_url
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'auth_user' => ks_user
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'auth_tenant' => ks_tenant
          )}
          it { should contain_class('neutron::agents::metadata').with(
            'auth_password' => ks_password
          )}

          if ha_agent
            it { should contain_class('cluster::neutron::metadata').with(
              'primary' => (node_role == 'primary-controller')
            )}
          else
            it { should_not contain_class('cluster::neutron::metadata') }
          end
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
