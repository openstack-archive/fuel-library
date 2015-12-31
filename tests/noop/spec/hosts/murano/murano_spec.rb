require 'spec_helper'
require 'shared-examples'
manifest = 'murano/murano.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:murano_user) { Noop.hiera_structure('murano/user', 'murano') }
    let(:murano_password) { Noop.hiera_structure('murano/user_password') }
    let(:tenant) { Noop.hiera_structure('murano/tenant', 'services') }
    let(:rabbit_os_user) { Noop.hiera_structure('rabbit/user', 'nova') }
    let(:rabbit_os_password) { Noop.hiera_structure('rabbit/password') }

    let(:rabbit_own_vhost) { '/' }
    let(:rabbit_own_port) { '55572' }

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:public_ip) do
      Noop.hiera 'public_vip'
    end

    let(:management_ip) do
      Noop.hiera 'management_vip'
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
    let(:internal_url) { "http://#{bind_address}:#{api_bind_port}" }

    let(:sql_connection) do
      if facts[:os_package_type] == 'debian'
        extra_params = '?charset=utf8&read_timeout=60'
      else
        extra_params = '?charset=utf8'
      end
      "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}#{extra_params}"
    end

    admin_auth_protocol = 'http'
    admin_auth_address = Noop.hiera('service_endpoint')
    primary_controller = Noop.hiera 'primary_controller'
    if Noop.hiera_structure('use_ssl', false)
      public_auth_protocol = 'https'
      public_auth_address = Noop.hiera_structure('use_ssl/keystone_public_hostname')
      admin_auth_protocol = 'https'
      admin_auth_address = Noop.hiera_structure('use_ssl/keystone_admin_hostname')
    elsif Noop.hiera_structure('public_ssl/services', false)
      public_auth_protocol = 'https'
      public_auth_address = Noop.hiera_structure('public_ssl/hostname')
    else
      public_auth_protocol = 'http'
      public_auth_address = Noop.hiera('public_vip')
    end

    let(:external_network) do
      if use_neutron
        Noop.puppet_function 'get_ext_net_name', predefined_networks
      else
        nil
      end
    end

    let(:default_dns) { Noop.hiera_structure('external_dns/dns_list') }

    #############################################################################

    enable = Noop.hiera_structure('murano/enabled')
    default_log_levels_hash = Noop.hiera_hash 'default_log_levels'
    default_log_levels = Noop.puppet_function 'join_keys_to_values',default_log_levels_hash,'='

    context 'if murano is enabled', :if => enable do
      it 'should declare murano class correctly' do
        should contain_class('murano').with(
                   'verbose'             => verbose,
                   'debug'               => debug,
                   'use_syslog'          => use_syslog,
                   'use_stderr'          => 'false',
                   'log_facility'        => syslog_log_facility_murano,
                   'database_connection' => sql_connection,
                   'sync_db'             => primary_controller,
                   'auth_uri'            => "#{public_auth_protocol}://#{public_auth_address}:5000/v2.0/",
                   'admin_user'          => murano_user,
                   'admin_password'      => murano_password,
                   'admin_tenant_name'   => tenant,
                   'identity_uri'        => "#{admin_auth_protocol}://#{admin_auth_address}:35357/",
                   'use_neutron'         => use_neutron,
                   'rabbit_os_user'      => rabbit_os_user,
                   'rabbit_os_password'  => rabbit_os_password,
                   'rabbit_os_port'      => amqp_port,
                   'rabbit_os_host'      => amqp_hosts.split(','),
                   'rabbit_ha_queues'    => rabbit_ha_queues,
                   'rabbit_own_host'     => public_ip,
                   'rabbit_own_port'     => rabbit_own_port,
                   'rabbit_own_user'     => rabbit_os_user,
                   'rabbit_own_password' => rabbit_os_password,
                   'rabbit_own_vhost'    => rabbit_own_vhost,
                   'default_nameservers' => default_dns,
                   'service_host'        => bind_address,
                   'service_port'        => api_bind_port,
                   'external_network'    => external_network,
               )
      end

      it 'should configure default_log_levels' do
        should contain_murano_config('DEFAULT/default_log_levels').with_value(default_log_levels.sort.join(','))
      end

      it 'should declare murano::api class correctly' do
        should contain_class('murano::api').with(
                   'host'    => bind_address,
                   'port'    => api_bind_port,
                   'sync_db' => false,
               )
      end

      it 'should declare murano::engine class coreclty' do
        should contain_class('murano::engine').with('sync_db' => false)
      end

      it 'should declare murano::client class coreclty' do
        should contain_class('murano::client')
      end

      it 'should declare murano::dashboard class correctly' do
        should contain_class('murano::dashboard').with(
                   'api_url' => nil,
                   'repo_url' => repository_url
               )
      end

      it { should_not contain_concat__fragment('murano_dashboard_section').with_content(/MURANO_API_URL = /)}
      it { should contain_concat__fragment('murano_dashboard_section').with_content(/METADATA_CACHE_DIR = '\/var\/cache\/murano-dashboard'/)}

      enable = (Noop.hiera_structure('murano/enabled') and Noop.hiera('role') == 'primary-controller')
      context 'on primary controller', :if => enable do
        it 'should declare murano::application resource correctly' do
          should contain_murano__application('io.murano')
        end

        it {
          should contain_haproxy_backend_status('keystone-public').that_comes_before('Haproxy_backend_status[murano-api]')
        }

        it {
          should contain_haproxy_backend_status('keystone-admin').that_comes_before('Haproxy_backend_status[murano-api]')
        }

        it {
          should contain_haproxy_backend_status('murano-api').that_comes_before('Murano::Application[io.murano]')
        }
      end
    end

  end

  test_ubuntu_and_centos manifest
end
