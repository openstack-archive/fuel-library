require 'spec_helper'
require 'shared-examples'
manifest = 'murano/murano.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:murano_user) { Noop.hiera_structure('murano/user', 'murano') }
    let(:murano_password) { Noop.hiera_structure('murano/user_password') }
    let(:murano_enabled) { Noop.hiera_structure('murano/enabled') }
    let(:tenant) { Noop.hiera_structure('murano/tenant', 'services') }
    let(:rabbit_os_user) { Noop.hiera_structure('rabbit/user', 'nova') }
    let(:rabbit_os_password) { Noop.hiera_structure('rabbit/password') }
    let(:rabbit_own_password) { Noop.hiera_structure('heat/rabbit_password') }
    let(:node_role) { Noop.hiera('node_role') }

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:public_ip) do
      Noop.hiera 'public_vip'
    end

    let(:bind_address) do
      prepare
      Noop.puppet_function 'get_network_role_property', 'murano/api', 'ipaddr'
    end

    let(:region) { Noop.hiera('region', 'RegionOne') }
    let(:use_neutron) { Noop.hiera('use_neutron', false) }
    let(:service_endpoint) { Noop.hiera('service_endpoint') }
    let(:syslog_log_facility_murano) { Noop.hiera('syslog_log_facility_murano') }
    let(:debug) { Noop.hiera('debug', false) }
    let(:verbose) { Noop.hiera('verbose', true) }
    let(:use_syslog) { Noop.hiera('use_syslog', true) }
    let(:rabbit_ha_queues) { Noop.hiera('rabbit_ha_queues') }
    let(:amqp_port) { Noop.hiera('amqp_port') }
    let(:amqp_hosts) { Noop.hiera('amqp_hosts') }
    let(:public_ssl) { Noop.hiera_structure('public_ssl/services') }

    let(:db_user) { Noop.hiera_structure('murano/db_user', 'murano') }
    let(:db_name) { Noop.hiera_structure('murano/db_name', 'murano') }
    let(:db_host) { Noop.hiera_structure('murano/db_host', service_endpoint) }
    let(:db_password) { Noop.hiera_structure('murano/db_password') }

    let(:predefined_networks) { Noop.hiera_structure('neutron_config/predefined_networks') }

    let(:default_repository_url) { 'http://storage.apps.openstack.org' }
    let(:repository_url) { Noop.hiera_structure('murano_settings/murano_repo_url', default_repository_url) }

    let(:api_bind_port) { '8082' }
    let(:internal_url) { "http://#{service_endpoint}:#{api_bind_port}" }

    let(:sql_connection) do
      read_timeout = '60'
      "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}?read_timeout=#{read_timeout}"
    end

    let(:public_ssl_hostname) do
      Noop.hiera_structure('public_ssl/hostname')
    end

    let(:public_protocol) { public_ssl ? 'https' : 'http' }
    let(:public_address) { public_ssl ? public_ssl_hostname : public_ip }

    let(:external_network) do
      if use_neutron
        Noop.puppet_function 'get_ext_net_name', predefined_networks
      else
        nil
      end
    end

    let(:check_enabled) do
      skip 'Murano is disabled' unless murano_enabled
    end

    let(:check_primary_controller) do
      skip 'Role is not primary-controller' unless node_role == 'primary-controller'
    end

    #############################################################################

    it 'should declare murano class correctly' do
      check_enabled

      should contain_class('murano').with(
                 'verbose' => verbose,
                 'debug' => debug,
                 'use_syslog' => use_syslog,
                 'use_stderr' => 'false',
                 'log_facility' => syslog_log_facility_murano,
                 'database_connection' => sql_connection,
                 'keystone_uri' => "#{public_protocol}://#{public_address}:5000/v2.0/",
                 'keystone_username' => murano_user,
                 'keystone_password' => murano_password,
                 'keystone_tenant' => tenant,
                 'identity_uri' => "http://#{service_endpoint}:35357/",
                 'use_neutron' => use_neutron,
                 'rabbit_os_user' => rabbit_os_user,
                 'rabbit_os_password' => rabbit_os_password,
                 'rabbit_os_port' => amqp_port,
                 'rabbit_os_host' => amqp_hosts.split(','),
                 'rabbit_ha_queues' => rabbit_ha_queues,
                 'rabbit_own_host' => public_ip,
                 'rabbit_own_port' => '55572',
                 'rabbit_own_user' => 'murano',
                 'rabbit_own_password' => rabbit_own_password,
                 'service_host' => bind_address,
                 'service_port' => api_bind_port,
                 'external_network' => external_network
             )
    end

    it 'should declare murano::api class correctly' do
      check_enabled

      should contain_class('murano::api').with(
                 'host' => bind_address,
                 'port' => api_bind_port
             )
    end

    it 'should declare murano::engine class coreclty' do
      check_enabled

      should contain_class('murano::engine')
    end

    it 'should declare murano::client class coreclty' do
      check_enabled

      should contain_class('murano::client')
    end

    it 'should declare murano::dashboard class correctly' do
      check_enabled

      should contain_class('murano::dashboard').with(
                 'api_url' => internal_url,
                 'repo_url' => repository_url
             )
    end

    it 'should declare murano::rabbitmq class correctly' do
      check_enabled

      should contain_class('murano::rabbitmq').with(
                 'rabbit_user' => 'murano',
                 'rabbit_password' => rabbit_own_password,
                 'rabbit_port' => '55572'
             )
    end

    context 'on primary controller' do
      it 'should declare murano::application resource correctly' do
        check_enabled
        check_primary_controller

        should contain_murano__application('io.murano').with(
                   'os_tenant_name' => tenant,
                   'os_username' => murano_user,
                   'os_password' => murano_password,
                   'os_auth_url' => "#{public_protocol}://#{public_address}:5000/v2.0/",
                   'os_region' => region,
                   'mandatory' => true
               )
      end

      it {
        check_enabled
        check_primary_controller
        should contain_haproxy_backend_status('keystone-public').that_comes_before('Haproxy_backend_status[murano-api]')
      }

      it {
        check_enabled
        check_primary_controller
        should contain_haproxy_backend_status('keystone-admin').that_comes_before('Haproxy_backend_status[murano-api]')
      }

      it {
        check_enabled
        check_primary_controller
        should contain_haproxy_backend_status('murano-api').that_comes_before('Murano::Application[io.murano]')
      }
    end

  end

  test_ubuntu_and_centos manifest
end
