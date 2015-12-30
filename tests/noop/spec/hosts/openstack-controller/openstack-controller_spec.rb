require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-controller/openstack-controller.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:configuration_override) do
      Noop.hiera_structure 'configuration'
    end

    let(:nova_config_override_resources) do
      configuration_override.fetch('nova_config', {})
    end

    let(:nova_paste_api_ini_override_resources) do
      configuration_override.fetch('nova_paste_api_ini', {})
    end

    network_metadata     = Noop.hiera 'network_metadata'
    memcache_roles       = Noop.hiera 'memcache_roles'
    memcache_addresses   = Noop.hiera 'memcached_addresses', false
    memcache_server_port = Noop.hiera 'memcache_server_port', '11211'

    let(:memcache_nodes) do
      Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, memcache_roles
    end

    let(:memcache_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', memcache_nodes, 'mgmt/memcache'
    end

    let (:memcache_servers) do
      if not memcache_addresses
        memcache_address_map.values.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
      else
        memcache_addresses.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
      end
    end

    use_neutron = Noop.hiera 'use_neutron'
    primary_controller = Noop.hiera 'primary_controller'
    if !use_neutron && primary_controller
      floating_ips_range = Noop.hiera 'floating_network_range'
      access_hash  = Noop.hiera_structure 'access'
    end
    service_endpoint = Noop.hiera 'service_endpoint'
    if service_endpoint
      keystone_host = service_endpoint
    else
      keystone_host = Noop.hiera 'management_vip'
    end

    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='

    storage_hash = Noop.hiera_structure 'storage'

    # TODO All this stuff should be moved to shared examples controller* tests.

    it 'should configure default_log_levels' do
      should contain_nova_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
    end

    # Nova config options
    it 'nova config should have use_stderr set to false' do
      should contain_nova_config('DEFAULT/use_stderr').with(
        'value' => 'false',
      )
    end

    it 'nova config should have report_interval set to 60' do
      should contain_nova_config('DEFAULT/report_interval').with(
        'value' => '60',
      )
    end

    it 'nova config should have service_down_time set to 180' do
      should contain_nova_config('DEFAULT/service_down_time').with(
        'value' => '180',
      )
    end

    it 'nova config should contain right memcached servers list' do
      should contain_nova_config('DEFAULT/memcached_servers').with(
        'value' => memcache_servers,
      )
    end

    keystone_ec2_url = "http://#{keystone_host}:5000/v2.0/ec2tokens"
    it 'should declare class nova::api with keystone_ec2_url' do
      should contain_class('nova::api').with(
        'keystone_ec2_url'    => keystone_ec2_url,
        'cinder_catalog_info' => 'volume:cinder:internalURL',
      )
    end

    it 'should configure keystone_ec2_url for nova api service' do
      should contain_nova_config('DEFAULT/keystone_ec2_url').with(
        'value' => keystone_ec2_url,
      )
    end

    it 'should configure nova quota for injected file path length' do
      should contain_class('nova::quota').with('quota_injected_file_path_length' => '4096')
      should contain_nova_config('DEFAULT/quota_injected_file_path_length').with(
        'value' => '4096',
      )
    end

    it 'nova config should be modified by override_resources' do
       is_expected.to contain_override_resources('nova_config').with(:data => nova_config_override_resources)
    end

    it 'should use "override_resources" to update the catalog' do
      ral_catalog = Noop.create_ral_catalog self
      nova_config_override_resources.each do |title, params|
        params['value'] = 'True' if params['value'].is_a? TrueClass
        expect(ral_catalog).to contain_nova_config(title).with(params)
      end
    end

    it 'nova_paste_api_ini should be modified by override_resources' do
      is_expected.to contain_override_resources('nova_paste_api_ini').with(:data => nova_paste_api_ini_override_resources)
    end

    it 'should use override_resources to update nova_paste_api_ini' do
      ral_catalog = Noop.create_ral_catalog self
      nova_paste_api_ini_override_resources.each do |title, params|
       params['value'] = 'True' if params['value'].is_a? TrueClass
       expect(ral_catalog).to contain_nova_paste_api_ini(title).with(params)
      end
    end

    #PUP-2299
    if primary_controller
      it 'should retry unless when creating m1.micro flavor' do
        should contain_exec('create-m1.micro-flavor').with(
           'command' => 'bash -c "nova flavor-create --is-public true m1.micro auto 64 0 1"',
           'unless'  => 'bash -c \'for tries in {1..10}; do
                    nova flavor-list | grep m1.micro;
                    status=("${PIPESTATUS[@]}");
                    (( ! status[0] )) && exit "${status[1]}";
                    sleep 2;
                  done; exit 1\'',
        )
      end
    end

    if floating_ips_range && access_hash
      if Noop.hiera_structure('use_ssl', false)
        internal_auth_protocol = 'https'
        keystone_host = Noop.hiera_structure('use_ssl/keystone_internal_hostname')
      else
        internal_auth_protocol = 'http'
      end
      floating_ips_range.each do |ips_range|
        it "should configure nova floating IP range for #{ips_range}" do
          should contain_nova_floating_range(ips_range).with(
            'ensure'      => 'present',
            'pool'        => 'nova',
            'username'    => access_hash['user'],
            'api_key'     => access_hash['password'],
            'auth_method' => 'password',
            'auth_url'    => "#{internal_auth_protocol}://#{keystone_host}:5000/v2.0/",
            'api_retries' => '10',
          )
        end
      end
    end

    ironic_enabled = Noop.hiera_structure 'ironic/enabled'
    if ironic_enabled
      it 'should declare nova::scheduler::filter class with scheduler_host_manager' do
        should contain_class('nova::scheduler::filter').with(
          'scheduler_host_manager' => 'nova.scheduler.ironic_host_manager.IronicHostManager',
        )
      end
    end

    it 'should install open-iscsi if ceph is used as cinder backend' do
      should contain_package('open-isci').with('ensure' => 'present')
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

