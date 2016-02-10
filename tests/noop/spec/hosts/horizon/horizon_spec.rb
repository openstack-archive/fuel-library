require 'spec_helper'
require 'shared-examples'
manifest = 'horizon/horizon.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:service_endpoint) do
      Noop.hiera 'service_endpoint'
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:bind_address) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'horizon', 'ipaddr'
    end

    let(:nova_quota) do
      Noop.hiera 'nova_quota'
    end

    let(:management_vip) do
      Noop.hiera 'management_vip'
    end

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }

    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[service_endpoint, management_vip] }

    let(:keystone_url) do
      "#{internal_auth_protocol}://#{internal_auth_address}:5000/v3"
    end

    let(:cache_options) do
      {
          'SOCKET_TIMEOUT' => 1,
          'SERVER_RETRIES' => 1,
          'DEAD_RETRY'     => 1,
      }
    end

    memcache_server_port = Noop.hiera 'memcache_server_port', '22122'

    let (:memcache_servers) do
      ['127.0.0.1']
    end

    storage_hash = Noop.hiera 'storage_hash'
    let(:cinder_options) do
      { 'enable_backup' => storage_hash.fetch('volumes_ceph', false) }
    end

    ###########################################################################

    it 'should declare openstack::horizon class' do
      should contain_class('openstack::horizon').with(
                 'cinder_options'     => cinder_options,
                 'hypervisor_options' => {'enable_quotas' => nova_quota},
                 'bind_address'       => bind_address
             )
    end

    it 'should declare openstack::horizon class with keystone_url with v3 API version' do
      should contain_class('openstack::horizon').with(
                 'keystone_url'      => keystone_url,
                 'cache_server_ip'   => memcache_servers,
                 'cache_server_port' => memcache_server_port,
                 'api_versions'      => {'identity' => 3},
             )
    end

    #it 'should specify default custom theme for horizon' do
    #  if facts[:os_package_type] == 'debian'
    #      custom_theme_path = 'themes/vendor'
    #  else
    #      custom_theme_path = 'undef'
    #  end
    #end

    it 'should declare horizon class with correct values' do
      #if !facts.has_key?(:os_package_type) or facts[:os_package_type] == 'debian'
      #    cache_backend = 'horizon.backends.memcached.HorizonMemcached'
      #else
      cache_backend = 'django.core.cache.backends.memcached.MemcachedCache'
      #end

      should contain_class('horizon').with(
                 'cache_backend'       => cache_backend,
                 'cache_options'       => cache_options,
                 'log_handler'         => 'file',
                 'overview_days_range' => 1,
             )
    end

    context 'with Neutron DVR', :if => Noop.hiera_structure('neutron_advanced_configuration/neutron_dvr') do
      it 'should configure horizon for neutron DVR' do
        should contain_class('openstack::horizon').with(
                   'neutron_options' => {
                       'enable_distributed_router' => Noop.hiera_structure('neutron_advanced_configuration/neutron_dvr')
                   }
               )
      end
    end


    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Class[openstack::horizon]", "Haproxy_backend_status[keystone-public]")
      expect(graph).to ensure_transitive_dependency("Class[openstack::horizon]", "Haproxy_backend_status[keystone-admin]")
    end


    it {
      should contain_service('httpd').with(
           'hasrestart' => true,
           'restart'    => 'sleep 30 && apachectl graceful || apachectl restart'
      )
    }

  end

  test_ubuntu_and_centos manifest
end

