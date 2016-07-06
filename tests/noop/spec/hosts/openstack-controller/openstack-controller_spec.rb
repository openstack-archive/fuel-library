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

    workers_max          = Noop.hiera 'workers_max'
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

    let (:memcached_servers) { Noop.hiera 'memcached_servers' }

    use_neutron = Noop.hiera 'use_neutron'
    primary_controller = Noop.hiera 'primary_controller'
    if !use_neutron && primary_controller
      floating_ips_range = Noop.hiera 'floating_network_range'
      access_hash  = Noop.hiera_structure 'access'
    end
    service_endpoint = Noop.hiera 'service_endpoint'
    management_vip = Noop.hiera 'management_vip'

    let(:nova_hash) { Noop.hiera_hash 'nova_hash' }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol',[nova_hash['auth_protocol'],'http'] }

    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[service_endpoint, management_vip] }

    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol',[nova_hash['auth_protocol'],'http'] }

    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname',[service_endpoint, management_vip] }

    let(:keystone_auth_uri) { "#{internal_auth_protocol}://#{internal_auth_address}:5000/" }
    let(:keystone_identity_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357/" }
    let(:keystone_ec2_url) { "#{keystone_auth_uri}v2.0/ec2tokens" }

    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='

    nova_internal_protocol = Noop.puppet_function 'get_ssl_property',
      Noop.hiera_hash('use_ssl', {}), {}, 'nova', 'internal', 'protocol',
      'http'
    nova_endpoint = Noop.hiera('nova_endpoint', Noop.hiera('management_vip'))
    nova_internal_endpoint = Noop.puppet_function 'get_ssl_property',
      Noop.hiera_hash('use_ssl', {}), {}, 'nova', 'internal', 'hostname',
      [nova_endpoint]

    # TODO All this stuff should be moved to shared examples controller* tests.

    it 'should declare openstack::controller class with 4 processess on 4 CPU & 32G system' do
      should contain_class('openstack::controller').with(
        'service_workers' => '4',
      )
    end

    it 'should configure workers for nova API, conductor services' do
      fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
      service_workers = nova_hash.fetch('workers', fallback_workers)
      should contain_nova_config('DEFAULT/osapi_compute_workers').with(:value => service_workers)
      should contain_nova_config('DEFAULT/ec2_workers').with(:value => service_workers)
      should contain_nova_config('DEFAULT/metadata_workers').with(:value => service_workers)
      should contain_nova_config('conductor/workers').with(:value => service_workers)
    end

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
      should contain_nova_config('keystone_authtoken/memcached_servers').with_value(memcached_servers.join(','))
    end

    it 'should declare class nova::api with keystone_ec2_url' do
      should contain_class('nova::api').with(
        'identity_uri'        => keystone_identity_uri,
        'auth_uri'            => keystone_auth_uri,
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
      floating_ips_range.each do |ips_range|
        it "should configure nova floating IP range for #{ips_range}" do
          should contain_nova_floating_range(ips_range).with(
            'ensure'      => 'present',
            'pool'        => 'nova',
            'username'    => access_hash['user'],
            'api_key'     => access_hash['password'],
            'auth_method' => 'password',
            'auth_url'    => "#{internal_auth_protocol}://#{internal_auth_address}:5000/v2.0/",
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

    if primary_controller
      it 'should have explicit ordering between LB classes and particular actions' do
        expect(graph).to ensure_transitive_dependency("Class[nova::api]","Haproxy_backend_status[nova-api]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[nova-api]",
                                                    "Exec[create-m1.micro-flavor]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]","Exec[create-m1.micro-flavor]")
        expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]","Exec[create-m1.micro-flavor]")
        franges = graph.vertices.find_all {|v| v.type == :nova_floating_range }
        if !franges.to_a.empty?
          franges.each do
            |frange|
            expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[nova-api]",frange.ref)
            expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",frange.ref)
            expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",frange.ref)
          end
        end
      end

      if Noop.hiera('external_lb', false)
        url = "#{nova_internal_protocol}://#{nova_internal_endpoint}:8774"
        provider = 'http'
      else
        url = 'http://' + Noop.hiera('service_endpoint').to_s + ':10000/;csv'
        provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
      end

      it {
        should contain_haproxy_backend_status('nova-api').with(
          :url      => url,
          :provider => provider
        )
      }
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end

