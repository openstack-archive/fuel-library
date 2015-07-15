require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/sahara.pp'

describe manifest do
  shared_examples 'catalog' do

    use_neutron          = Noop.hiera 'use_neutron'
    rabbit_user          = Noop.hiera_structure 'rabbit_hash/user'
    rabbit_password      = Noop.hiera_structure 'rabbit_hash/password'
    sahara_enabled       = Noop.hiera_structure 'sahara/enabled'
    sahara_user_password = Noop.hiera_structure 'sahara/user_password'
    ceilometer_enabled   = Noop.hiera_structure 'ceilometer/enabled'
    auth_user            = Noop.hiera_structure 'access/user'
    auth_password        = Noop.hiera_structure 'access/password'
    auth_tenant          = Noop.hiera_structure 'access/tenant'
    primary_controller   = Noop.hiera('primary_controller')
    public_ip            = Noop.hiera('public_vip')
    management_ip        = Noop.hiera('management_vip')
    internal_address     = Noop.hiera('internal_address')
    region               = Noop.hiera('region', 'RegionOne')
    amqp_port            = Noop.hiera('amqp_port')
    amqp_hosts           = Noop.hiera('amqp_hosts')
    debug                = Noop.hiera('debug', false)
    verbose              = Noop.hiera('verbose', true)
    use_syslog           = Noop.hiera('use_syslog', true)
    log_facility_sahara  = Noop.hiera('syslog_log_facility_sahara')
    rabbit_ha_queues     = Noop.hiera('rabbit_ha_queues')

    # Sahara
    if sahara_enabled
      firewall_rule   = '201 sahara-api'
      api_bind_port   = '8386'
      api_bind_host   = internal_address
      api_workers     = '4'
      sahara_user     = Noop.hiera_structure('sahara/user', 'sahara')
      tenant          = Noop.hiera_structure('sahara/tenant', 'services')
      public_url      = "http://#{public_ip}:#{api_bind_port}/v1.1/%(tenant_id)s"
      admin_url       = "http://#{management_ip}:#{api_bind_port}/v1.1/%(tenant_id)s"
      internal_url    = "http://#{internal_address}:#{api_bind_port}/v1.1/%(tenant_id)s"
      db_user         = Noop.hiera_structure('sahara/db_user', 'sahara')
      db_name         = Noop.hiera_structure('sahara/db_name', 'sahara')
      db_password     = Noop.hiera_structure 'sahara/db_password'
      db_host         = Noop.hiera_structure('sahara/db_host', management_ip)
      read_timeout    = '60'
      sql_connection  = "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}?read_timeout=#{read_timeout}"

      it 'should declare sahara::keystone::auth class correctly' do
        should contain_class('sahara::keystone::auth').with(
          'password'     => sahara_user_password,
          'service_type' => 'data_processing',
          'region'       => region,
          'tenant'       => tenant,
          'public_url'   => public_url,
          'admin_url'    => admin_url,
          'internal_url' => internal_url,
        )
      end

      it 'should declare sahara class correctly' do
        should contain_class('sahara').with(
          'auth_uri'            => "http://#{management_ip}:5000/v2.0/",
          'identity_uri'        => "http://#{management_ip}:35357/",
          'rpc_backend'         => 'rabbit',
          'use_neutron'         => use_neutron,
          'admin_user'          => sahara_user,
          'verbose'             => verbose,
          'debug'               => debug,
          'use_syslog'          => use_syslog,
          'log_facility'        => log_facility_sahara,
          'database_connection' => sql_connection,
          'admin_password'      => sahara_user_password,
          'admin_tenant_name'   => tenant,
          'rabbit_userid'       => rabbit_user,
          'rabbit_password'     => rabbit_password,
          'rabbit_ha_queues'    => rabbit_ha_queues,
          'rabbit_port'         => amqp_port,
          'rabbit_hosts'        => amqp_hosts.split(","),
        )
      end

      it 'should declare sahara::api class correctly' do
        should contain_class('sahara::api').with(
          'api_workers' => api_workers,
          'host'        => api_bind_host,
          'port'        => api_bind_port,
        )
      end

      it 'should declare sahara::engine class correctly' do
        should contain_class('sahara::engine').with(
          'infrastructure_engine' => 'heat',
        )
      end

      it 'should declare sahara::client class correctly' do
        should contain_class('sahara::client')
      end

      if ceilometer_enabled
        it 'should declare sahara::notify class correctly' do
          should contain_class('sahara::notify').with(
            'enable_notifications' => true,
          )
        end
      end

      if primary_controller
        it 'should declare sahara_templates class correctly' do
          should contain_class('sahara_templates::create_templates').with(
            'use_neutron'   => use_neutron,
            'auth_uri'      => "http://#{management_ip}:5000/v2.0/",
            'auth_password' => auth_password,
            'auth_user'     => auth_user,
            'auth_tenant'   => auth_tenant,
          )
        end
      end
    end
  end
  test_ubuntu_and_centos manifest
end
