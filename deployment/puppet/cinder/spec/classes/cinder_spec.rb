require 'spec_helper'
describe 'cinder' do
  let :req_params do
    {:rabbit_password => 'guest', :database_connection => 'mysql://user:password@host/database'}
  end

  let :facts do
    {:osfamily => 'Debian'}
  end

  describe 'with only required params' do
    let :params do
      req_params
    end

    it { should contain_class('cinder::params') }
    it { should contain_class('mysql::python') }

    it 'should contain default config' do
      should contain_cinder_config('DEFAULT/rpc_backend').with(
        :value => 'cinder.openstack.common.rpc.impl_kombu'
      )
      should contain_cinder_config('DEFAULT/control_exchange').with(
        :value => 'openstack'
      )
      should contain_cinder_config('DEFAULT/rabbit_password').with(
        :value => 'guest',
        :secret => true
      )
      should contain_cinder_config('DEFAULT/rabbit_host').with(
        :value => '127.0.0.1'
      )
      should contain_cinder_config('DEFAULT/rabbit_port').with(
        :value => '5672'
      )
      should contain_cinder_config('DEFAULT/rabbit_hosts').with(
        :value => '127.0.0.1:5672'
      )
      should contain_cinder_config('DEFAULT/rabbit_ha_queues').with(
        :value => false
      )
      should contain_cinder_config('DEFAULT/rabbit_virtual_host').with(
        :value => '/'
      )
      should contain_cinder_config('DEFAULT/rabbit_userid').with(
        :value => 'guest'
      )
      should contain_cinder_config('database/connection').with(
        :value  => 'mysql://user:password@host/database',
        :secret => true
      )
      should contain_cinder_config('database/idle_timeout').with(
        :value => '3600'
      )
      should contain_cinder_config('DEFAULT/verbose').with(
        :value => false
      )
      should contain_cinder_config('DEFAULT/debug').with(
        :value => false
      )
      should contain_cinder_config('DEFAULT/api_paste_config').with(
        :value => '/etc/cinder/api-paste.ini'
      )
      should contain_cinder_config('DEFAULT/log_dir').with(:value => '/var/log/cinder')
    end

    it { should contain_file('/etc/cinder/cinder.conf').with(
      :owner   => 'cinder',
      :group   => 'cinder',
      :mode    => '0600',
      :require => 'Package[cinder]'
    ) }

    it { should contain_file('/etc/cinder/api-paste.ini').with(
      :owner   => 'cinder',
      :group   => 'cinder',
      :mode    => '0600',
      :require => 'Package[cinder]'
    ) }

  end
  describe 'with modified rabbit_hosts' do
    let :params do
      req_params.merge({'rabbit_hosts' => ['rabbit1:5672', 'rabbit2:5672']})
    end

    it 'should contain many' do
      should_not contain_cinder_config('DEFAULT/rabbit_host')
      should_not contain_cinder_config('DEFAULT/rabbit_port')
      should contain_cinder_config('DEFAULT/rabbit_hosts').with(
        :value => 'rabbit1:5672,rabbit2:5672'
      )
      should contain_cinder_config('DEFAULT/rabbit_ha_queues').with(
        :value => true
      )
    end
  end

  describe 'with a single rabbit_hosts entry' do
    let :params do
      req_params.merge({'rabbit_hosts' => ['rabbit1:5672']})
    end

    it 'should contain many' do
      should_not contain_cinder_config('DEFAULT/rabbit_host')
      should_not contain_cinder_config('DEFAULT/rabbit_port')
      should contain_cinder_config('DEFAULT/rabbit_hosts').with(
        :value => 'rabbit1:5672'
      )
      should contain_cinder_config('DEFAULT/rabbit_ha_queues').with(
        :value => true
      )
    end
  end

  describe 'with qpid rpc supplied' do

    let :params do
      {
        :database_connection => 'mysql://user:password@host/database',
        :qpid_password       => 'guest',
        :rpc_backend         => 'cinder.openstack.common.rpc.impl_qpid'
      }
    end

    it { should contain_cinder_config('database/connection').with_value('mysql://user:password@host/database') }
    it { should contain_cinder_config('DEFAULT/rpc_backend').with_value('cinder.openstack.common.rpc.impl_qpid') }
    it { should contain_cinder_config('DEFAULT/qpid_hostname').with_value('localhost') }
    it { should contain_cinder_config('DEFAULT/qpid_port').with_value('5672') }
    it { should contain_cinder_config('DEFAULT/qpid_username').with_value('guest') }
    it { should contain_cinder_config('DEFAULT/qpid_password').with_value('guest').with_secret(true) }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect').with_value(true) }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_timeout').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_limit').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_interval_min').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_interval_max').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_interval').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_heartbeat').with_value('60') }
    it { should contain_cinder_config('DEFAULT/qpid_protocol').with_value('tcp') }
    it { should contain_cinder_config('DEFAULT/qpid_tcp_nodelay').with_value(true) }
  end

  describe 'with qpid rpc and no qpid_sasl_mechanisms' do
    let :params do
      {
        :database_connection  => 'mysql://user:password@host/database',
        :qpid_password        => 'guest',
        :rpc_backend          => 'cinder.openstack.common.rpc.impl_qpid'
      }
    end

    it { should contain_cinder_config('DEFAULT/qpid_sasl_mechanisms').with_ensure('absent') }
  end

  describe 'with qpid rpc and qpid_sasl_mechanisms string' do
    let :params do
      {
        :database_connection  => 'mysql://user:password@host/database',
        :qpid_password        => 'guest',
        :qpid_sasl_mechanisms => 'PLAIN',
        :rpc_backend          => 'cinder.openstack.common.rpc.impl_qpid'
      }
    end

    it { should contain_cinder_config('DEFAULT/qpid_sasl_mechanisms').with_value('PLAIN') }
  end

  describe 'with qpid rpc and qpid_sasl_mechanisms array' do
    let :params do
      {
        :database_connection  => 'mysql://user:password@host/database',
        :qpid_password        => 'guest',
        :qpid_sasl_mechanisms => [ 'DIGEST-MD5', 'GSSAPI', 'PLAIN' ],
        :rpc_backend          => 'cinder.openstack.common.rpc.impl_qpid'
      }
    end

    it { should contain_cinder_config('DEFAULT/qpid_sasl_mechanisms').with_value('DIGEST-MD5 GSSAPI PLAIN') }
  end

  describe 'with syslog disabled' do
    let :params do
      req_params
    end

    it { should contain_cinder_config('DEFAULT/use_syslog').with_value(false) }
  end

  describe 'with syslog enabled' do
    let :params do
      req_params.merge({
        :use_syslog   => 'true',
      })
    end

    it { should contain_cinder_config('DEFAULT/use_syslog').with_value(true) }
    it { should contain_cinder_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
  end

  describe 'with syslog enabled and custom settings' do
    let :params do
      req_params.merge({
        :use_syslog   => 'true',
        :log_facility => 'LOG_LOCAL0'
     })
    end

    it { should contain_cinder_config('DEFAULT/use_syslog').with_value(true) }
    it { should contain_cinder_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0') }
  end

  describe 'with log_dir disabled' do
    let(:params) { req_params.merge!({:log_dir => false}) }
    it { should contain_cinder_config('DEFAULT/log_dir').with_ensure('absent') }
  end

  describe 'with amqp_durable_queues disabled' do
    let :params do
      req_params
    end

    it { should contain_cinder_config('DEFAULT/amqp_durable_queues').with_value(false) }
  end

  describe 'with amqp_durable_queues enabled' do
    let :params do
      req_params.merge({
        :amqp_durable_queues => true,
      })
    end

    it { should contain_cinder_config('DEFAULT/amqp_durable_queues').with_value(true) }
  end

  describe 'with postgresql' do
    let :params do
      {
        :database_connection      => 'postgresql://user:drowssap@host/database',
        :rabbit_password       => 'guest',
      }
    end

    it { should contain_cinder_config('database/connection').with(
      :value  => 'postgresql://user:drowssap@host/database',
      :secret => true
    ) }
    it { should_not contain_class('mysql::python') }
    it { should_not contain_class('mysql::bindings') }
    it { should_not contain_class('mysql::bindings::python') }
  end
end
