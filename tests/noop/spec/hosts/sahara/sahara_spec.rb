require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/sahara.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:use_neutron) { Noop.hiera 'use_neutron' }
    let(:rabbit_user) { Noop.hiera_structure 'rabbit/user', 'nova' }
    let(:rabbit_password) { Noop.hiera_structure 'rabbit/password' }
    let(:auth_user) { Noop.hiera_structure 'access/user' }
    let(:auth_password) { Noop.hiera_structure 'access/password' }
    let(:auth_tenant) { Noop.hiera_structure 'access/tenant' }
    let(:service_endpoint) { Noop.hiera('service_endpoint') }
    let(:public_vip) { Noop.hiera('public_vip') }

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

    ############################################################################

    context 'if sahara is enabled', :if =>  Noop.hiera_structure('sahara/enabled') do
      it 'should declare sahara class correctly' do
        sahara_plugins = %w(ambari cdh mapr spark vanilla)
        sahara_user = Noop.hiera_structure('sahara_hash/user', 'sahara')
        sahara_password = Noop.hiera_structure('sahara_hash/user_password')
        tenant = Noop.hiera_structure('sahara_hash/tenant', 'services')
        db_user = Noop.hiera_structure('sahara_hash/db_user', 'sahara')
        db_name = Noop.hiera_structure('sahara_hash/db_name', 'sahara')
        db_password = Noop.hiera_structure('sahara_hash/db_password')
        db_host = Noop.hiera_structure('sahara_hash/db_host', database_vip)
        read_timeout = '60'
        sql_connection = "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}?read_timeout=#{read_timeout}"

        should contain_class('sahara').with(
                   'auth_uri' => "http://#{service_endpoint}:5000/v2.0/",
                   'identity_uri' => "http://#{service_endpoint}:35357/",
                   'plugins' => sahara_plugins,
                   'rpc_backend' => 'rabbit',
                   'use_neutron' => use_neutron,
                   'admin_user' => sahara_user,
                   'verbose' => verbose,
                   'debug' => debug,
                   'use_syslog' => use_syslog,
                   'use_stderr' => 'false',
                   'log_facility' => log_facility_sahara,
                   'database_connection' => sql_connection,
                   'admin_password' => sahara_password,
                   'admin_tenant_name' => tenant,
                   'rabbit_userid' => rabbit_user,
                   'rabbit_password' => rabbit_password,
                   'rabbit_ha_queues' => rabbit_ha_queues,
                   'rabbit_port' => amqp_port,
                   'rabbit_hosts' => amqp_hosts.split(",")
               )
      end

      it 'should declare sahara::api class correctly' do
        api_bind_port = '8386'
        should contain_class('sahara::api').with(
                   'host' => bind_address,
                   'port' => api_bind_port
               )
      end

      it 'should declare sahara::engine class correctly' do
        should contain_class('sahara::engine')
      end

      it 'should declare sahara::client class correctly' do
        should contain_class('sahara::client')
      end

      context 'with ceilometer', :if => Noop.hiera_structure('ceilometer/enabled') do
        it 'should declare sahara::notify class correctly' do
          should contain_class('sahara::notify').with(
                     'enable_notifications' => true
                 )
        end
      end

      context 'on primary-controller', :if => Noop.hiera('node_role') == 'primary-controller' do

        it 'should declare sahara_templates class correctly' do
          should contain_class('sahara_templates::create_templates').with(
                     'use_neutron' => use_neutron,
                     'auth_uri' => "#{public_protocol}://#{public_address}:5000/v2.0/",
                     'auth_password' => auth_password,
                     'auth_user' => auth_user,
                     'auth_tenant' => auth_tenant
                 )
        end

        it {
          should contain_haproxy_backend_status('keystone-public').that_comes_before('Haproxy_backend_status[sahara]')
        }

        it {
          should contain_haproxy_backend_status('keystone-admin').that_comes_before('Haproxy_backend_status[sahara]')
        }

        it {
          should contain_haproxy_backend_status('sahara').that_comes_before('Class[sahara_templates::create_templates]')
        }
      end
    end

  end
  test_ubuntu_and_centos manifest
end
