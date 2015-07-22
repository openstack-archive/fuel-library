require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/sahara.pp'

describe manifest do
  shared_examples 'catalog' do

    use_neutron          = Noop.hiera 'use_neutron'
    rabbit_user          = Noop.hiera_structure 'rabbit_hash/user'
    rabbit_password      = Noop.hiera_structure 'rabbit_hash/password'
    ceilometer_enabled   = Noop.hiera_structure 'ceilometer_hash/enabled'
    auth_user            = Noop.hiera_structure 'access_hash/user'
    auth_password        = Noop.hiera_structure 'access_hash/password'
    auth_tenant          = Noop.hiera_structure 'access_hash/tenant'
    primary_controller   = Noop.hiera('primary_controller')
    service_endpoint     = Noop.hiera('service_endpoint')
    public_vip           = Noop.hiera('public_vip')
    internal_address     = Noop.hiera('internal_address')
    database_vip         = Noop.hiera('database_vip', internal_address)
    amqp_port            = Noop.hiera('amqp_port')
    amqp_hosts           = Noop.hiera('amqp_hosts')
    debug                = Noop.hiera('debug', false)
    verbose              = Noop.hiera('verbose', true)
    use_syslog           = Noop.hiera('use_syslog', true)
    log_facility_sahara  = Noop.hiera('syslog_log_facility_sahara')
    rabbit_ha_queues     = Noop.hiera('rabbit_ha_queues')
    public_ssl           = Noop.hiera_structure('public_ssl/services')

    firewall_rule   = '201 sahara-api'
    api_bind_port   = '8386'
    api_bind_host   = internal_address
    api_workers     = '4'
    if public_ssl
      public_address  = Noop.hiera_structure('public_ssl/hostname')
      public_protocol = 'https'
    else
      public_address  = public_vip
      public_protocol = 'http'
    end
    sahara_user     = Noop.hiera_structure('sahara_hash/user', 'sahara')
    sahara_password = Noop.hiera_structure('sahara_hash/user_password')
    tenant          = Noop.hiera_structure('sahara_hash/tenant', 'services')
    db_user         = Noop.hiera_structure('sahara_hash/db_user', 'sahara')
    db_name         = Noop.hiera_structure('sahara_hash/db_name', 'sahara')
    db_password     = Noop.hiera_structure('sahara_hash/db_password')
    db_host         = Noop.hiera_structure('sahara_hash/db_host', database_vip)
    read_timeout    = '60'
    sql_connection  = "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}?read_timeout=#{read_timeout}"

    it 'should declare sahara class correctly' do
      should contain_class('sahara').with(
        'auth_uri'            => "#{public_protocol}://#{public_address}:5000/v2.0/",
        'identity_uri'        => "http://#{service_endpoint}:35357/",
        'rpc_backend'         => 'rabbit',
        'use_neutron'         => use_neutron,
        'admin_user'          => sahara_user,
        'verbose'             => verbose,
        'debug'               => debug,
        'use_syslog'          => use_syslog,
        'log_facility'        => log_facility_sahara,
        'database_connection' => sql_connection,
        'admin_password'      => sahara_password,
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

# Temporarily disable as workaround for bug 1476324
#    if primary_controller
#      it 'should declare sahara_templates class correctly' do
#        should contain_class('sahara_templates::create_templates').with(
#        'use_neutron'   => use_neutron,
#        'auth_uri'      => "http://#{management_ip}:5000/v2.0/",
#        'auth_password' => auth_password,
#        'auth_user'     => auth_user,
#        'auth_tenant'   => auth_tenant,
#        )
#      end
#    end
  end
  test_ubuntu_and_centos manifest
end
