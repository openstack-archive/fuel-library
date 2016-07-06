require 'spec_helper'
require 'shared-examples'
manifest = 'sahara/sahara.pp'

describe manifest do
  shared_examples 'catalog' do

    use_neutron          = Noop.hiera 'use_neutron'
    rabbit_user          = Noop.hiera_structure 'rabbit_hash/user'
    rabbit_password      = Noop.hiera_structure 'rabbit_hash/password'
    sahara_enabled       = Noop.hiera_structure 'sahara_hash/enabled'
    ceilometer_enabled   = Noop.hiera_structure 'ceilometer_hash/enabled'
    auth_user            = Noop.hiera_structure 'access_hash/user'
    auth_password        = Noop.hiera_structure 'access_hash/password'
    auth_tenant          = Noop.hiera_structure 'access_hash/tenant'
    primary_controller   = Noop.hiera('primary_controller')
    service_endpoint     = Noop.hiera('service_endpoint')
    public_vip           = Noop.hiera('public_vip')
    bind_address         = Noop.hiera('internal_address') # TODO: smakar change AFTER https://bugs.launchpad.net/fuel/+bug/1486048
    database_vip         = Noop.hiera('database_vip', bind_address)
    amqp_port            = Noop.hiera('amqp_port')
    amqp_hosts           = Noop.hiera('amqp_hosts')
    debug                = Noop.hiera('debug', false)
    verbose              = Noop.hiera('verbose', true)
    use_syslog           = Noop.hiera('use_syslog', true)
    log_facility_sahara  = Noop.hiera('syslog_log_facility_sahara')
    rabbit_ha_queues     = Noop.hiera('rabbit_ha_queues')
    public_ssl           = Noop.hiera_structure('public_ssl/services')
    let(:memcached_servers) { Noop.hiera('memcached_servers') }

    if sahara_enabled
      firewall_rule   = '201 sahara-api'
      api_bind_port   = '8386'
      api_bind_host   = bind_address
      sahara_plugins  = [ 'ambari', 'cdh', 'mapr', 'spark', 'vanilla' ]
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
      max_retries     = '-1'
      idle_timeout    = '3600'
      read_timeout    = '60'
      sql_connection  = "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}?read_timeout=#{read_timeout}"

      it 'should declare sahara class correctly' do
        should contain_class('sahara').with(
          'auth_uri'            => "http://#{service_endpoint}:5000/v2.0/",
          'identity_uri'        => "http://#{service_endpoint}:35357/",
          'plugins'             => sahara_plugins,
          'rpc_backend'         => 'rabbit',
          'use_neutron'         => use_neutron,
          'admin_user'          => sahara_user,
          'verbose'             => verbose,
          'debug'               => debug,
          'use_syslog'          => use_syslog,
          'use_stderr'          => 'false',
          'log_facility'        => log_facility_sahara,
          'database_connection' => sql_connection,
          'max_retries'         => max_retries,
          'idle_timeout'        => idle_timeout,
          'admin_password'      => sahara_password,
          'admin_tenant_name'   => tenant,
          'rabbit_userid'       => rabbit_user,
          'rabbit_password'     => rabbit_password,
          'rabbit_ha_queues'    => rabbit_ha_queues,
          'rabbit_port'         => amqp_port,
          'rabbit_hosts'        => amqp_hosts.split(","),
        )

        should contain_sahara_config('keystone_authtoken/memcached_servers').with_value(memcached_servers.join(','))
      end

      it 'should configure sahara db params' do
        facts[:processorcount] = 10
        max_pool_size          = [facts[:processorcount] * 5 + 0, 30 + 0].min
        max_overflow           = [facts[:processorcount] * 5 + 0, 60 + 0].min
        is_expected.to contain_sahara_config('database/max_pool_size').with_value(max_pool_size)
        is_expected.to contain_sahara_config('database/max_overflow').with_value(max_overflow)
      end

      if public_ssl
        it { should contain_file('/etc/pki/tls/certs').with(
           'mode' => 755,
        )}

        it { should contain_file('/etc/pki/tls/certs/public_haproxy.pem').with(
           'mode' => 644,
        )}

        it { is_expected.to contain_sahara_config('object_store_access/public_identity_ca_file').with_value('/etc/pki/tls/certs/public_haproxy.pem') }
        it { is_expected.to contain_sahara_config('object_store_access/public_object_store_ca_file').with_value('/etc/pki/tls/certs/public_haproxy.pem') }
      end

      it 'should declare sahara::api class correctly' do
        should contain_class('sahara::api').with(
          'host' => api_bind_host,
          'port' => api_bind_port,
        )
      end

      it 'should declare sahara::engine class correctly' do
        should contain_class('sahara::engine')
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
          'auth_uri'      => "#{public_protocol}://#{public_address}:5000/v2.0/",
          'auth_password' => auth_password,
          'auth_user'     => auth_user,
          'auth_tenant'   => auth_tenant,
          )
        end

        it { should contain_haproxy_backend_status('keystone-public').that_comes_before('Haproxy_backend_status[sahara]') }
        it { should contain_haproxy_backend_status('keystone-admin').that_comes_before('Haproxy_backend_status[sahara]') }
        it { should contain_haproxy_backend_status('sahara').that_comes_before('Class[sahara_templates::create_templates]') }
      end
    end
  end
  test_ubuntu_and_centos manifest
end
