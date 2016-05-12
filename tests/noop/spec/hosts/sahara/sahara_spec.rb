# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/sahara.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do

    let(:use_neutron) { Noop.hiera 'use_neutron' }
    let(:rabbit_user) { Noop.hiera_structure 'rabbit/user', 'nova' }
    let(:rabbit_password) { Noop.hiera_structure 'rabbit/password' }
    let(:auth_user) { Noop.hiera_structure 'access/user' }
    let(:auth_password) { Noop.hiera_structure 'access/password' }
    let(:auth_tenant) { Noop.hiera_structure 'access/tenant' }
    let(:service_endpoint) { Noop.hiera('service_endpoint') }
    let(:public_vip) { Noop.hiera('public_vip') }
    let(:internal_net) { Noop.hiera_structure('neutron_config/default_private_net', 'admin_internal_net') }

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:bind_address) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'sahara/api', 'ipaddr'
    end

    let(:public_ip) do
      Noop.hiera 'public_vip'
    end

    let(:public_ssl_hostname) do
      Noop.hiera_structure('public_ssl/hostname')
    end

    let(:database_vip) { Noop.hiera('database_vip', bind_address) }
    let(:amqp_port) { Noop.hiera('amqp_port') }
    let(:amqp_hosts) { Noop.hiera('amqp_hosts') }
    let(:debug) { Noop.hiera('debug', false) }
    let(:verbose) { Noop.hiera('verbose', true) }
    let(:use_syslog) { Noop.hiera('use_syslog', true) }
    let(:log_facility_sahara) { Noop.hiera('syslog_log_facility_sahara') }
    let(:rabbit_ha_queues) { Noop.hiera('rabbit_ha_queues') }
    let(:public_ssl) { Noop.hiera_structure('public_ssl/services') }

    let(:public_protocol) { public_ssl ? 'https' : 'http' }
    let(:public_address) { public_ssl ? public_ssl_hostname : public_ip }

    let(:api_bind_port) { '8386' }

    let(:ssl_hash) { Noop.hiera_hash 'use_ssl', {} }

    let (:sahara_protocol){
      Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'sahara',
        'internal', 'protocol', 'http'
    }

    let (:sahara_address){
      Noop.puppet_function 'get_ssl_property', ssl_hash, {}, 'sahara',
        'internal', 'hostname',
        [Noop.hiera('service_endpoint', ''), Noop.hiera('management_vip')]
    }

    let (:sahara_url){
      "#{sahara_protocol}://#{sahara_address}:#{api_bind_port}"
    }

    let(:admin_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone', 'admin','protocol','http' }
    let(:admin_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin', 'hostname', [Noop.hiera('service_endpoint', Noop.hiera('management_vip'))]}
    let(:admin_uri) { "#{admin_auth_protocol}://#{admin_auth_address}:35357" }
    let(:internal_auth_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol','http' }
    let(:internal_auth_address) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname',[Noop.hiera('service_endpoint', ''), Noop.hiera('management_vip')] }
    let(:auth_url) { "#{internal_auth_protocol}://#{internal_auth_address}:5000/v2.0/" }

    ############################################################################

    enable = Noop.hiera_structure('sahara/enabled')
    context 'if sahara is enabled', :if => enable do
      it 'should declare sahara class correctly' do
        facts[:processorcount] = 10
        sahara_plugins = %w(ambari cdh mapr spark vanilla)
        sahara_user = Noop.hiera_structure('sahara/user', 'sahara')
        sahara_password = Noop.hiera_structure('sahara/user_password')
        primary_controller = Noop.hiera 'primary_controller'
        tenant = Noop.hiera_structure('sahara/tenant', 'services')
        db_user = Noop.hiera_structure('sahara/db_user', 'sahara')
        db_name = Noop.hiera_structure('sahara/db_name', 'sahara')
        db_password = Noop.hiera_structure('sahara/db_password')
        db_host = Noop.hiera_structure('sahara/db_host', database_vip)
        max_pool_size =[facts[:processorcount] * 5 + 0, 30 + 0].min
        max_overflow = [facts[:processorcount] * 5 + 0, 60 + 0].min
        max_retries  = '-1'
        idle_timeout = '3600'
        read_timeout = '60'
        if facts[:os_package_type] == 'debian'
          extra_params = '?charset=utf8&read_timeout=60'
        else
          extra_params = '?charset=utf8'
        end
        sql_connection = "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}#{extra_params}"

        should contain_class('sahara').with(
                   'auth_uri'               => auth_url,
                   'identity_uri'           => admin_uri,
                   'plugins'                => sahara_plugins,
                   'rpc_backend'            => 'rabbit',
                   'use_neutron'            => use_neutron,
                   'admin_user'             => sahara_user,
                   'verbose'                => verbose,
                   'debug'                  => debug,
                   'use_syslog'             => use_syslog,
                   'use_stderr'             => 'false',
                   'log_facility'           => log_facility_sahara,
                   'database_connection'    => sql_connection,
                   'database_max_pool_size' => max_pool_size,
                   'database_max_overflow'  => max_overflow,
                   'database_max_retries'   => max_retries,
                   'database_idle_timeout'  => idle_timeout,
                   'sync_db'                => primary_controller,
                   'admin_password'         => sahara_password,
                   'admin_tenant_name'      => tenant,
                   'rabbit_userid'          => rabbit_user,
                   'rabbit_password'        => rabbit_password,
                   'rabbit_ha_queues'       => rabbit_ha_queues,
                   'rabbit_port'            => amqp_port,
                   'rabbit_hosts'           => amqp_hosts.split(","),
                   'host'                   => bind_address,
                   'port'                   => '8386'
               )
      end

      default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
      default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='
      it 'should configure default_log_levels' do
        should contain_sahara_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      end

      it 'should contain tweak for service override' do
        should contain_tweaks__ubuntu_service_override('sahara-api')
      end

      enable = (Noop.hiera_structure('sahara/enabled') and Noop.hiera_structure('public_ssl/services'))
      context 'with public_ssl enabled', :if => enable do
        it { should contain_file('/etc/pki/tls/certs').with(
           'mode' => '0755'
        )}

        it { should contain_file('/etc/pki/tls/certs/public_haproxy.pem').with(
           'mode' => '0644'
        )}

        it { is_expected.to contain_sahara_config('object_store_access/public_identity_ca_file').with_value('/etc/pki/tls/certs/public_haproxy.pem') }
        it { is_expected.to contain_sahara_config('object_store_access/public_object_store_ca_file').with_value('/etc/pki/tls/certs/public_haproxy.pem') }
      end

      it 'should declare sahara::api class correctly' do
        should contain_class('sahara::service::api')
      end

      it 'should declare sahara::engine class correctly' do
        should contain_class('sahara::service::engine')
      end

      it 'should declare sahara::client class correctly' do
        should contain_class('sahara::client')
      end

      it 'should test sahara-dashboard package' do
        if facts[:os_package_type] == 'debian'
          should contain_package('sahara-dashboard').with(
            :ensure => :present,
            :name   => 'python-sahara-dashboard',
          )
        else
          should_not contain_package('sahara-dashboard')
        end
      end

      enable = (Noop.hiera_structure('sahara/enabled') and Noop.hiera_structure('ceilometer/enabled'))
      context 'with ceilometer', :if => enable do
        it 'should declare sahara::notify class correctly' do
          should contain_class('sahara::notify').with(
                     'enable_notifications' => true
                 )
        end
      end

      enable = (Noop.hiera_structure('sahara/enabled') and Noop.hiera('role') == 'primary-controller')
      context 'on primary-controller', :if => enable do

        it 'should declare sahara_templates class correctly' do
          should contain_class('sahara_templates::create_templates').with(
                     'use_neutron' => use_neutron,
                     'auth_uri' => "#{public_protocol}://#{public_address}:5000/v2.0/",
                     'auth_password' => auth_password,
                     'auth_user' => auth_user,
                     'auth_tenant' => auth_tenant,
                     'internal_net' => internal_net,
                 )
        end

        it 'should have explicit ordering between LB classes and particular actions' do
          expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-public]",
                                                      "Haproxy_backend_status[sahara]")
          expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[keystone-admin]",
                                                      "Haproxy_backend_status[sahara]")
          expect(graph).to ensure_transitive_dependency("Haproxy_backend_status[sahara]",
                                                      "Class[sahara_templates::create_templates]")
        end
      end

      it {
        if Noop.hiera('external_lb', false)
          url = sahara_url
          provider = 'http'
        else
          url = "http://#{Noop.hiera('management_vip')}:10000/;csv"
          provider = Puppet::Type.type(:haproxy_backend_status).defaultprovider.name
        end
        should contain_haproxy_backend_status('sahara').with(
          :url      => url,
          :provider => provider
        )
      }

      it 'should configure kombu compression' do
        kombu_compression = Noop.hiera 'kombu_compression', facts[:os_service_default]
        should contain_sahara_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
      end
    end

  end # end of shared_examples
  test_ubuntu_and_centos manifest
end
