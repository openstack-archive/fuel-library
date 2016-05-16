require 'spec_helper'
require 'shared-examples'
manifest = 'heat/heat.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:memcache_address) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'mgmt/memcache', 'ipaddr'
    end

    public_vip = Noop.hiera('public_vip')
    admin_auth_protocol = 'http'
    admin_auth_address = Noop.hiera('service_endpoint')
    if Noop.hiera_structure('use_ssl', false)
      public_auth_protocol = 'https'
      public_auth_address = Noop.hiera_structure('use_ssl/keystone_public_hostname')
      public_heat_protocol = 'https'
      public_heat_address = Noop.hiera_structure('use_ssl/heat_public_hostname')
      admin_auth_protocol = 'https'
      admin_auth_address = Noop.hiera_structure('use_ssl/keystone_admin_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      public_auth_protocol = 'https'
      public_auth_address = Noop.hiera_structure('public_ssl/hostname')
      public_heat_protocol = 'https'
      public_heat_address = Noop.hiera_structure('public_ssl/hostname')
    else
      public_auth_protocol = 'http'
      public_heat_protocol = 'http'
      public_auth_address = public_vip
      public_heat_address = public_vip
    end

    use_syslog = Noop.hiera 'use_syslog'
    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
    primary_controller = Noop.hiera 'primary_controller'
    sahara = Noop.hiera_structure('sahara/enabled')

    it 'should install heat-docker package only after heat-engine' do
      should contain_package('heat-docker').with(
        'ensure'  => 'installed',
        'require' => 'Package[heat-engine]',
    )
    end

    it 'should configure default_log_levels' do
      should contain_heat_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
    end

    if sahara
      it 'should configure ' do
        should contain_heat_config('DEFAULT/reauthentication_auth_method').with_value('trusts')
      end
    end

    it 'should use auth_uri and identity_uri' do
      should contain_class('openstack::heat').with(
        'auth_uri'           => "#{public_auth_protocol}://#{public_auth_address}:5000/v2.0/",
        'identity_uri'       => "#{admin_auth_protocol}://#{admin_auth_address}:35357/",
        'primary_controller' => primary_controller,
      )
    end

    it 'should set empty trusts_delegated_roles for heat engine' do
      should contain_class('heat::engine').with(
        'trusts_delegated_roles' => [],
      )
      should contain_heat_config('DEFAULT/trusts_delegated_roles').with(
        'value' => [],
      )
    end

    it 'should configure template size and request limit' do
      should contain_heat_config('DEFAULT/max_template_size').with_value('5440000')
      should contain_heat_config('DEFAULT/max_resources_per_stack').with_value('20000')
      should contain_heat_config('DEFAULT/max_json_body_size').with_value('10880000')
    end

    it 'should configure caching for validation process' do
      should contain_heat_config('cache/enabled').with_value('true')
      should contain_heat_config('cache/backend').with_value('oslo_cache.memcache_pool')
      should contain_heat_config('cache/memcache_servers').with_value("#{memcache_address}:11211")
    end

    it 'should configure urls for metadata, cloudwatch and waitcondition servers' do
      should contain_heat_config('DEFAULT/heat_metadata_server_url').with_value("#{public_heat_protocol}://#{public_heat_address}:8000")
      should contain_heat_config('DEFAULT/heat_waitcondition_server_url').with_value("#{public_heat_protocol}://#{public_heat_address}:8000/v1/waitcondition")
      should contain_heat_config('DEFAULT/heat_watch_server_url').with_value("#{public_heat_protocol}://#{public_heat_address}:8003")
    end

    it 'should configure heat rpc response timeout' do
      should contain_heat_config('DEFAULT/rpc_response_timeout').with_value('600')
    end

    it 'should configure syslog rfc format for heat' do
      should contain_heat_config('DEFAULT/use_syslog_rfc_format').with(:value => use_syslog)
    end

    it 'should disable use_stderr for heat' do
      should contain_heat_config('DEFAULT/use_stderr').with(:value => 'false')
    end

    it 'should configure region name for heat' do
      region = Noop.hiera 'region'
      if !region
        region = 'RegionOne'
      end
      should contain_heat_config('DEFAULT/region_name_for_services').with(
        'value' => region,
      )
    end

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Class[heat::keystone::domain]")
      expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Class[heat::keystone::domain]")
    end
    if Noop.hiera('external_lb', false)
      url = "#{admin_auth_protocol}://#{admin_auth_address}:35357/v3"
      provider = 'http'
    else
      url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
      provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
    end

    it {
      should contain_haproxy_backend_status('keystone-admin').with(
        :url      => "#{url}",
        :provider => provider
      )
    }

  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

