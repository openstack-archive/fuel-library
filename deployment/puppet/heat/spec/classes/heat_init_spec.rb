require 'spec_helper'

describe 'heat' do

  let :params do
    {
      :package_ensure        => 'present',
      :verbose               => 'False',
      :debug                 => 'False',
      :log_dir               => '/var/log/heat',
      :rabbit_host           => '127.0.0.1',
      :rabbit_port           => 5672,
      :rabbit_userid         => 'guest',
      :rabbit_password       => '',
      :rabbit_virtual_host   => '/',
      :sql_connection        => 'mysql://user@host/database',
      :database_idle_timeout => 3600,
      :auth_uri              => 'http://127.0.0.1:5000/v2.0',
      :keystone_ec2_uri      => 'http://127.0.0.1:5000/v2.0/ec2tokens',
      :mysql_module          => '0.9'
    }
  end

  let :qpid_params do
    {
      :rpc_backend   => "heat.openstack.common.rpc.impl_qpid",
      :qpid_hostname => 'localhost',
      :qpid_port     => 5672,
      :qpid_username => 'guest',
      :qpid_password  => 'guest',
    }
  end

  shared_examples_for 'heat' do

    context 'with rabbit_host parameter' do
      it_configures 'a heat base installation'
      it_configures 'rabbit without HA support (with backward compatibility)'
    end

    context 'with rabbit_hosts parameter' do
      context 'with one server' do
        before { params.merge!( :rabbit_hosts => ['127.0.0.1:5672'] ) }
        it_configures 'a heat base installation'
        it_configures 'rabbit without HA support (without backward compatibility)'
      end

      context 'with multiple servers' do
        before { params.merge!(
          :rabbit_hosts => ['rabbit1:5672', 'rabbit2:5672'],
          :amqp_durable_queues => true) }
        it_configures 'a heat base installation'
        it_configures 'rabbit with HA support'
      end
    end

    context 'with qpid instance' do
      before {params.merge!(qpid_params) }

      it_configures 'a heat base installation'
      it_configures 'qpid as rpc backend'
    end

    it_configures 'with syslog disabled'
    it_configures 'with syslog enabled'
    it_configures 'with syslog enabled and custom settings'
  end

  shared_examples_for 'a heat base installation' do

    it { should contain_class('heat::params') }

    it 'configures heat group' do
      should contain_group('heat').with(
        :name    => 'heat',
        :require => 'Package[heat-common]'
      )
    end

    it 'configures heat user' do
      should contain_user('heat').with(
        :name    => 'heat',
        :gid     => 'heat',
        :groups  => ['heat'],
        :system  => true,
        :require => 'Package[heat-common]'
      )
    end

    it 'configures heat configuration folder' do
      should contain_file('/etc/heat/').with(
        :ensure  => 'directory',
        :owner   => 'heat',
        :group   => 'heat',
        :mode    => '0750',
        :require => 'Package[heat-common]'
      )
    end

    it 'configures heat configuration file' do
      should contain_file('/etc/heat/heat.conf').with(
        :owner   => 'heat',
        :group   => 'heat',
        :mode    => '0640',
        :require => 'Package[heat-common]'
      )
    end

    it 'installs heat common package' do
      should contain_package('heat-common').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name]
      )
    end


    it 'configures debug and verbose' do
      should contain_heat_config('DEFAULT/debug').with_value( params[:debug] )
      should contain_heat_config('DEFAULT/verbose').with_value( params[:verbose] )
    end

    it 'configures auth_uri' do
      should contain_heat_config('keystone_authtoken/auth_uri').with_value( params[:auth_uri] )
    end

    it 'configures logging directory by default' do
      should contain_heat_config('DEFAULT/log_dir').with_value( params[:log_dir] )
    end

    context 'with logging directory disabled' do
      before { params.merge!( :log_dir => false) }

      it { should contain_heat_config('DEFAULT/log_dir').with_ensure('absent') }
    end

    it 'configures sql_connection' do
      should contain_heat_config('database/connection').with_value( params[:sql_connection] )
    end

    it 'configures database_idle_timeout' do
      should contain_heat_config('database/idle_timeout').with_value( params[:database_idle_timeout] )
    end

    context("failing if sql_connection is invalid") do
      before { params[:sql_connection] = 'foo://foo:bar@baz/moo' }
      it { expect { should raise_error(Puppet::Error) } }
    end

    it 'configures keystone_ec2_uri' do
      should contain_heat_config('ec2authtoken/auth_uri').with_value( params[:keystone_ec2_uri] )
    end

  end

  shared_examples_for 'rabbit without HA support (with backward compatibility)' do
    it 'configures rabbit' do
      should contain_heat_config('DEFAULT/rabbit_userid').with_value( params[:rabbit_userid] )
      should contain_heat_config('DEFAULT/rabbit_password').with_value( params[:rabbit_password] )
      should contain_heat_config('DEFAULT/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
      should contain_heat_config('DEFAULT/rabbit_use_ssl').with_value(false)
      should contain_heat_config('DEFAULT/kombu_ssl_ca_certs').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_certfile').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_keyfile').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_version').with_ensure('absent')
    end
    it { should contain_heat_config('DEFAULT/rabbit_host').with_value( params[:rabbit_host] ) }
    it { should contain_heat_config('DEFAULT/rabbit_port').with_value( params[:rabbit_port] ) }
    it { should contain_heat_config('DEFAULT/rabbit_hosts').with_value( "#{params[:rabbit_host]}:#{params[:rabbit_port]}" ) }
    it { should contain_heat_config('DEFAULT/rabbit_ha_queues').with_value('false') }
    it { should contain_heat_config('DEFAULT/amqp_durable_queues').with_value(false) }
  end

  shared_examples_for 'rabbit without HA support (without backward compatibility)' do
    it 'configures rabbit' do
      should contain_heat_config('DEFAULT/rabbit_userid').with_value( params[:rabbit_userid] )
      should contain_heat_config('DEFAULT/rabbit_password').with_value( params[:rabbit_password] )
      should contain_heat_config('DEFAULT/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
      should contain_heat_config('DEFAULT/rabbit_use_ssl').with_value(false)
      should contain_heat_config('DEFAULT/kombu_ssl_ca_certs').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_certfile').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_keyfile').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_version').with_ensure('absent')
    end
    it { should contain_heat_config('DEFAULT/rabbit_host').with_ensure('absent') }
    it { should contain_heat_config('DEFAULT/rabbit_port').with_ensure('absent') }
    it { should contain_heat_config('DEFAULT/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') ) }
    it { should contain_heat_config('DEFAULT/rabbit_ha_queues').with_value('false') }
    it { should contain_heat_config('DEFAULT/amqp_durable_queues').with_value(false) }
  end

  shared_examples_for 'rabbit with HA support' do
    it 'configures rabbit' do
      should contain_heat_config('DEFAULT/rabbit_userid').with_value( params[:rabbit_userid] )
      should contain_heat_config('DEFAULT/rabbit_password').with_value( params[:rabbit_password] )
      should contain_heat_config('DEFAULT/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
      should contain_heat_config('DEFAULT/rabbit_use_ssl').with_value(false)
      should contain_heat_config('DEFAULT/kombu_ssl_ca_certs').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_certfile').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_keyfile').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_version').with_ensure('absent')
    end
    it { should contain_heat_config('DEFAULT/rabbit_host').with_ensure('absent') }
    it { should contain_heat_config('DEFAULT/rabbit_port').with_ensure('absent') }
    it { should contain_heat_config('DEFAULT/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') ) }
    it { should contain_heat_config('DEFAULT/rabbit_ha_queues').with_value('true') }
    it { should contain_heat_config('DEFAULT/amqp_durable_queues').with_value(true) }
  end


  shared_examples_for 'qpid as rpc backend' do
    context("with default parameters") do
      it { should contain_heat_config('DEFAULT/qpid_reconnect').with_value(true) }
      it { should contain_heat_config('DEFAULT/qpid_reconnect_timeout').with_value('0') }
      it { should contain_heat_config('DEFAULT/qpid_reconnect_limit').with_value('0') }
      it { should contain_heat_config('DEFAULT/qpid_reconnect_interval_min').with_value('0') }
      it { should contain_heat_config('DEFAULT/qpid_reconnect_interval_max').with_value('0') }
      it { should contain_heat_config('DEFAULT/qpid_reconnect_interval').with_value('0') }
      it { should contain_heat_config('DEFAULT/qpid_heartbeat').with_value('60') }
      it { should contain_heat_config('DEFAULT/qpid_protocol').with_value('tcp') }
      it { should contain_heat_config('DEFAULT/qpid_tcp_nodelay').with_value(true) }
      it { should contain_heat_config('DEFAULT/amqp_durable_queues').with_value(false) }
    end

    context("with mandatory parameters set") do
      it { should contain_heat_config('DEFAULT/rpc_backend').with_value('heat.openstack.common.rpc.impl_qpid') }
      it { should contain_heat_config('DEFAULT/qpid_hostname').with_value( params[:qpid_hostname] ) }
      it { should contain_heat_config('DEFAULT/qpid_port').with_value( params[:qpid_port] ) }
      it { should contain_heat_config('DEFAULT/qpid_username').with_value( params[:qpid_username]) }
      it { should contain_heat_config('DEFAULT/qpid_password').with_value(params[:qpid_password]) }
    end

    context("failing if the rpc_backend is not present") do
      before { params.delete( :rpc_backend) }
      it { expect { should raise_error(Puppet::Error) } }
    end
  end

  shared_examples_for 'with syslog disabled' do
    it { should contain_heat_config('DEFAULT/use_syslog').with_value(false) }
  end

  shared_examples_for 'with syslog enabled' do
    before do
      params.merge!(
        :use_syslog => 'true'
      )
    end

    it do
      should contain_heat_config('DEFAULT/use_syslog').with_value(true)
      should contain_heat_config('DEFAULT/syslog_log_facility').with_value('LOG_USER')
    end
  end

  shared_examples_for 'with syslog enabled and custom settings' do
    before do
      params.merge!(
        :use_syslog    => 'true',
        :log_facility  => 'LOG_LOCAL0'
      )
    end

    it do
      should contain_heat_config('DEFAULT/use_syslog').with_value(true)
      should contain_heat_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0')
    end
  end

  shared_examples_for 'with database_idle_timeout modified' do
    before do
      params.merge!(
        :database_idle_timeout => 69
      )
    end

    it do
      should contain_heat_config('database/idle_timeout').with_value(69)
    end
  end

  shared_examples_for 'with ec2authtoken auth uri set' do
    before do
      params.merge!(
        :keystone_ec2_uri => 'http://1.2.3.4:35357/v2.0/ec2tokens'
      )
    end

    it do
      should contain_heat_config('ec2authtoken/auth_uri').with_value('http://1.2.3.4:35357/v2.0/ec2tokens')
    end
  end

  shared_examples_for 'with auth uri set' do
    before do
      params.merge!(
        :auth_uri => 'http://1.2.3.4:35357/v2.0'
      )
    end

    it do
      should contain_heat_config('keystone_authtoken/auth_uri').with_value('http://1.2.3.4:35357/v2.0')
    end
  end

  context 'with rabbit_use_ssl parameter' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    let :params do
      { :rabbit_use_ssl => 'true' }
    end

    it 'configures rabbit' do
      should contain_heat_config('DEFAULT/rabbit_use_ssl').with_value(true)
      should contain_heat_config('DEFAULT/amqp_durable_queues').with_value(false)
      should contain_heat_config('DEFAULT/kombu_ssl_ca_certs').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_certfile').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_keyfile').with_ensure('absent')
      should contain_heat_config('DEFAULT/kombu_ssl_version').with_value('SSLv3')
    end
  end

  context 'with amqp ssl parameters' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    let :params do
      { :rabbit_use_ssl     => 'true',
        :kombu_ssl_ca_certs => '/etc/ca.cert',
        :kombu_ssl_certfile => '/etc/certfile',
        :kombu_ssl_keyfile  => '/etc/key',
        :kombu_ssl_version  => 'TLSv1', }
    end

    it 'configures rabbit' do
      should contain_heat_config('DEFAULT/rabbit_use_ssl').with_value(true)
      should contain_heat_config('DEFAULT/kombu_ssl_ca_certs').with_value('/etc/ca.cert')
      should contain_heat_config('DEFAULT/kombu_ssl_certfile').with_value('/etc/certfile')
      should contain_heat_config('DEFAULT/kombu_ssl_keyfile').with_value('/etc/key')
      should contain_heat_config('DEFAULT/kombu_ssl_version').with_value('TLSv1')
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :common_package_name => 'heat-common' }
    end

    it_configures 'heat'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :common_package_name => 'openstack-heat-common' }
    end

    it_configures 'heat'
  end
end
