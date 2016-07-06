require 'spec_helper'
require 'shared-examples'
manifest = 'murano/murano.pp'

describe manifest do
  shared_examples 'catalog' do

    murano_user                = Noop.hiera_structure('murano_hash/user', 'murano')
    murano_password            = Noop.hiera_structure('murano_hash/user_password')
    murano_enabled             = Noop.hiera_structure('murano_hash/enabled')
    tenant                     = Noop.hiera_structure('murano_hash/tenant', 'services')
    rabbit_os_user             = Noop.hiera_structure('rabbit_hash/user')
    rabbit_os_password         = Noop.hiera_structure('rabbit_hash/password')
    rabbit_own_password        = Noop.hiera_structure('heat_hash/rabbit_password')
    node_role                  = Noop.hiera('node_role')
    public_ip                  = Noop.hiera('public_vip')
    management_ip              = Noop.hiera('management_vip')
    bind_address               = Noop.hiera('internal_address') # TODO: smakar change AFTER https://bugs.launchpad.net/fuel/+bug/1486048
    region                     = Noop.hiera('region', 'RegionOne')
    use_neutron                = Noop.hiera('use_neutron', false)
    service_endpoint           = Noop.hiera('service_endpoint', management_ip)
    syslog_log_facility_murano = Noop.hiera('syslog_log_facility_murano')
    debug                      = Noop.hiera('debug', false)
    verbose                    = Noop.hiera('verbose', true)
    use_syslog                 = Noop.hiera('use_syslog', true)
    rabbit_ha_queues           = Noop.hiera('rabbit_ha_queues')
    amqp_port                  = Noop.hiera('amqp_port')
    amqp_hosts                 = Noop.hiera('amqp_hosts')
    public_ssl                 = Noop.hiera_structure('public_ssl/services')

    db_user                    = Noop.hiera_structure('murano_hash/db_user', 'murano')
    db_name                    = Noop.hiera_structure('murano_hash/db_name', 'murano')
    db_host                    = Noop.hiera_structure('murano_hash/db_host', management_ip)
    db_password                = Noop.hiera_structure('murano_hash/db_password')

    predefined_networks        = Noop.hiera_structure('neutron_config/predefined_networks')
    repository_url             = Noop.hiera_structure('murano_settings/murano_repo_url')

    let(:memcached_servers) { Noop.hiera('memcached_servers') }

    if murano_enabled
      api_bind_port              = '8082'
      api_bind_host              = bind_address

      internal_url               = "http://#{api_bind_host}:#{api_bind_port}"

      read_timeout               = '60'
      sql_connection             = "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}?read_timeout=#{read_timeout}"

      if public_ssl
          public_protocol = 'https'
          public_address  = Noop.hiera_structure('public_ssl/hostname')
      else
          public_protocol = 'http'
          public_address  = public_ip
      end

      if use_neutron
        external_network = Noop.puppet_function 'get_ext_net_name', predefined_networks
      else
        external_network = nil
      end

      if repository_url
        apps_repository = repository_url
      else
        apps_repository = 'http://storage.apps.openstack.org'
      end

      it 'should declare murano class correctly' do
        should contain_class('murano').with(
                   'verbose'             => verbose,
                   'debug'               => debug,
                   'use_syslog'          => use_syslog,
                   'use_stderr'          => 'false',
                   'log_facility'        => syslog_log_facility_murano,
                   'database_connection' => sql_connection,
                   'keystone_uri'        => "#{public_protocol}://#{public_address}:5000/v2.0/",
                   'keystone_username'   => murano_user,
                   'keystone_password'   => murano_password,
                   'keystone_tenant'     => tenant,
                   'identity_uri'        => "http://#{service_endpoint}:35357/",
                   'use_neutron'         => use_neutron,
                   'rabbit_os_user'      => rabbit_os_user,
                   'rabbit_os_password'  => rabbit_os_password,
                   'rabbit_os_port'      => amqp_port,
                   'rabbit_os_hosts'     => amqp_hosts.split(','),
                   'rabbit_ha_queues'    => rabbit_ha_queues,
                   'rabbit_own_host'     => public_ip,
                   'rabbit_own_port'     => '55572',
                   'rabbit_own_user'     => 'murano',
                   'rabbit_own_password' => rabbit_own_password,
                   'service_host'        => api_bind_host,
                   'service_port'        => api_bind_port,
                   'external_network'    => external_network,
               )
      end

      it 'should configure keystone_authtoken memcached_servers' do
        should contain_murano_config('keystone_authtoken/memcached_servers').with_value(memcached_servers.join(','))
      end

      it 'should declare murano::api class correctly' do
        should contain_class('murano::api').with(
                   'host' => api_bind_host,
                   'port' => api_bind_port,
               )
      end

      it 'should declare murano::engine class coreclty' do
        should contain_class('murano::engine')
      end

      it 'should declare murano::client class coreclty' do
        should contain_class('murano::client')
      end

      it 'should declare murano::dashboard class correctly' do
        should contain_class('murano::dashboard').with(
                   'api_url'  => internal_url,
                   'repo_url' => apps_repository,
               )
      end

      it 'should declare murano::rabbitmq class correctly' do
        should contain_class('murano::rabbitmq').with(
                   'rabbit_user'     => 'murano',
                   'rabbit_password' => rabbit_own_password,
                   'rabbit_port'     => '55572',
               )
      end

      if node_role == 'primary-controller'
        it 'should declare murano::application resource correctly' do
          should contain_murano__application('io.murano').with(
                     'os_tenant_name' => tenant,
                     'os_username'    => murano_user,
                     'os_password'    => murano_password,
                     'os_auth_url'    => "#{public_protocol}://#{public_address}:5000/v2.0/",
                     'os_region'      => region,
                     'mandatory'      => true,
                 )
        end

        it { should contain_haproxy_backend_status('keystone-public').that_comes_before('Haproxy_backend_status[murano-api]') }
        it { should contain_haproxy_backend_status('keystone-admin').that_comes_before('Haproxy_backend_status[murano-api]') }
        it { should contain_haproxy_backend_status('murano-api').that_comes_before('Murano::Application[io.murano]') }
      end
    end
  end
  test_ubuntu_and_centos manifest
end
