# ROLE: primary-controller
# ROLE: controller

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

    let(:public_ssl_hash) { Noop.hiera_hash 'public_ssl', {} }

    let(:public_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash, public_ssl_hash,'keystone','public','protocol','http' }

    let(:public_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash, public_ssl_hash,'keystone','public','hostname',[service_endpoint, management_vip] }

    let(:keystone_url) do
      "#{public_auth_protocol}://#{public_auth_address}:5000/v3"
    end

    let(:cache_options) do
      {
          'SOCKET_TIMEOUT' => 1,
          'SERVER_RETRIES' => 1,
          'DEAD_RETRY'     => 1,
      }
    end

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
        memcache_address_map.values
      else
        memcache_addresses
      end
    end

    let(:horizon_hash) { Noop.hiera_hash 'horizon', {} }
    let(:file_upload_max_size) do
      Noop.puppet_function 'pick', horizon_hash['upload_max_size'], '10737418235'
    end

    let(:neutron_advanced_config) { Noop.hiera_hash 'neutron_advanced_configuration', {} }

    let(:enable_lb) { Noop.puppet_function 'pick', neutron_advanced_config['neutron_lb'], false }
    let(:enable_firewall) { Noop.puppet_function 'pick', neutron_advanced_config['neutron_firewall'], false }
    let(:enable_quotas) { Noop.puppet_function 'pick', neutron_advanced_config['neutron_quotas'], true }
    let(:enable_security_group) { Noop.puppet_function 'pick', neutron_advanced_config['neutron_security_group'], true }
    let(:enable_vpn) { Noop.puppet_function 'pick', neutron_advanced_config['neutron_vpn'], false }
    let(:enable_distributed_router) { Noop.puppet_function 'pick', neutron_advanced_config['neutron_dvr'], false }
    let(:enable_ha_router) { Noop.puppet_function 'pick', neutron_advanced_config['neutron_ha_router'], false }
    let(:profile_support) { Noop.puppet_function 'pick', neutron_advanced_config['neutron_profile_support'], 'None' }

    it 'contains ::horizon::wsgi::apache' do
      if facts[:osfamily] == 'Debian' and file_upload_max_size
        custom_fragment = "\n  <Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>\n    Order allow,deny\n    Allow from all\n  </Directory>\n\n  LimitRequestBody #{file_upload_max_size}\n\n"
      elsif facts[:osfamily] == 'Debian' and not file_upload_max_size
        custom_fragment = "\n  <Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>\n    Order allow,deny\n    Allow from all\n  </Directory>\n\n"
      elsif facts[:osfamily] == 'RedHat'
        custom_fragment = "\n  <Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>\n    <IfModule mod_deflate.c>\n      SetOutputFilter DEFLATE\n      <IfModule mod_headers.c>\n        # Make sure proxies don't deliver the wrong content\n        Header append Vary User-Agent env=!dont-vary\n      </IfModule>\n    </IfModule>\n\n    Order allow,deny\n    Allow from all\n  </Directory>\n\n  <Directory /usr/share/openstack-dashboard/static>\n    <IfModule mod_expires.c>\n      ExpiresActive On\n      ExpiresDefault \"access 6 month\"\n    </IfModule>\n    <IfModule mod_deflate.c>\n      SetOutputFilter DEFLATE\n    </IfModule>\n\n    Order allow,deny\n    Allow from all\n  </Directory>\n\n  LimitRequestBody 10737418235\n\n"
      end

      should contain_class('horizon::wsgi::apache').with(
        'extra_params' => {
          'add_listen'        => false,
          'ip_based'          => true,
          'custom_fragment'   => custom_fragment,
          'default_vhost'     => true,
          'headers'           => ["set X-XSS-Protection \"1; mode=block\"", "set X-Content-Type-Options nosniff", "always append X-Frame-Options SAMEORIGIN"],
          'options'           => '-Indexes',
          'setenvif'          => 'X-Forwarded-Proto https HTTPS=1',
          'access_log_format' => '%{X-Forwarded-For}i %l %u %{%d/%b/%Y:%T}t.%{msec_frac}t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"'
        }
      )
    end

    storage_hash = Noop.hiera_hash 'storage'
    let(:cinder_options) do
      { 'enable_backup' => storage_hash.fetch('volumes_ceph', false) }
    end

    ###########################################################################

    it 'should declare horizon class' do
      should contain_class('horizon').with(
                 'cinder_options'     => cinder_options,
                 'hypervisor_options' => {'enable_quotas' => nova_quota},
                 'bind_address'       => bind_address
             )
    end

    it 'should declare horizon class with keystone_url with v3 API version' do
      should contain_class('horizon').with(
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

    it 'should configure horizon to use advanced neutron options' do
      should contain_class('horizon').with(
        'neutron_options' => {
          'enable_lb'                 => enable_lb,
          'enable_firewall'           => enable_firewall,
          'enable_quotas'             => enable_quotas,
          'enable_security_group'     => enable_security_group,
          'enable_vpn'                => enable_vpn,
          'enable_distributed_router' => enable_distributed_router,
          'enable_ha_router'          => enable_ha_router,
          'profile_support'           => profile_support,
        }
      )
    end

    it 'should have explicit ordering between LB classes and particular actions' do
      expect(graph).to ensure_transitive_dependency("Class[horizon]", "Haproxy_backend_status[keystone-public]")
      expect(graph).to ensure_transitive_dependency("Class[horizon]", "Haproxy_backend_status[keystone-admin]")
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
