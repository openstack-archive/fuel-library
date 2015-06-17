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
      :database_connection   => 'mysql://user@host/database',
      :database_idle_timeout => 3600,
      :auth_uri              => 'http://127.0.0.1:5000/v2.0',
      :keystone_ec2_uri      => 'http://127.0.0.1:5000/v2.0/ec2tokens',
      :flavor                => 'keystone',
      :keystone_password     => 'secretpassword',
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
    it_configures 'with SSL enabled with kombu'
    it_configures 'with SSL enabled without kombu'
    it_configures 'with SSL disabled'
    it_configures 'with SSL wrongly configured'
    it_configures "with custom keystone identity_uri"
    it_configures "with custom keystone identity_uri and auth_uri"
    it_configures 'with enable_stack_adopt and enable_stack_abandon set'
  end

  shared_examples_for 'a heat base installation' do

    it { is_expected.to contain_class('heat::params') }

    it 'configures heat group' do
      is_expected.to contain_group('heat').with(
        :name    => 'heat',
        :require => 'Package[heat-common]'
      )
    end

    it 'configures heat user' do
      is_expected.to contain_user('heat').with(
        :name    => 'heat',
        :gid     => 'heat',
        :groups  => ['heat'],
        :system  => true,
        :require => 'Package[heat-common]'
      )
    end

    it 'configures heat configuration folder' do
      is_expected.to contain_file('/etc/heat/').with(
        :ensure  => 'directory',
        :owner   => 'heat',
        :group   => 'heat',
        :mode    => '0750',
        :require => 'Package[heat-common]'
      )
    end

    it 'configures heat configuration file' do
      is_expected.to contain_file('/etc/heat/heat.conf').with(
        :owner   => 'heat',
        :group   => 'heat',
        :mode    => '0640',
        :require => 'Package[heat-common]'
      )
    end

    it 'installs heat common package' do
      is_expected.to contain_package('heat-common').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name],
        :tag    => 'openstack'
      )
    end

    it 'has db_sync enabled' do
      is_expected.to contain_exec('heat-dbsync').with(
        :subscribe => 'Package[heat-common]',
      )
    end

    it 'configures debug and verbose' do
      is_expected.to contain_heat_config('DEFAULT/debug').with_value( params[:debug] )
      is_expected.to contain_heat_config('DEFAULT/verbose').with_value( params[:verbose] )
    end

    it 'configures auth_uri' do
      is_expected.to contain_heat_config('keystone_authtoken/auth_uri').with_value( params[:auth_uri] )
    end

    it 'configures logging directory by default' do
      is_expected.to contain_heat_config('DEFAULT/log_dir').with_value( params[:log_dir] )
    end

    context 'with logging directory disabled' do
      before { params.merge!( :log_dir => false) }

      it { is_expected.to contain_heat_config('DEFAULT/log_dir').with_ensure('absent') }
    end

    it 'configures database_connection' do
      is_expected.to contain_heat_config('database/connection').with_value( params[:database_connection] )
    end

    it 'configures database_idle_timeout' do
      is_expected.to contain_heat_config('database/idle_timeout').with_value( params[:database_idle_timeout] )
    end

    context("failing if database_connection is invalid") do
      before { params[:database_connection] = 'foo://foo:bar@baz/moo' }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    context("with deprecated sql_connection parameter") do
      before { params[:sql_connection] = 'mysql://a:b@c/d' }
      it { is_expected.to contain_heat_config('database/connection').with_value( params[:sql_connection] )}
    end

    it 'configures keystone_ec2_uri' do
      is_expected.to contain_heat_config('ec2authtoken/auth_uri').with_value( params[:keystone_ec2_uri] )
    end

    it { is_expected.to contain_heat_config('paste_deploy/flavor').with_value('keystone') }

    it 'keeps keystone secrets secret' do
      is_expected.to contain_heat_config('keystone_authtoken/admin_password').with_secret(true)
    end


  end

  shared_examples_for 'rabbit without HA support (with backward compatibility)' do
    it 'configures rabbit' do
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_userid').with_value( params[:rabbit_userid] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_password').with_secret( true )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value(false)
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_version').with_ensure('absent')
    end
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_host').with_value( params[:rabbit_host] ) }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_port').with_value( params[:rabbit_port] ) }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_hosts').with_value( "#{params[:rabbit_host]}:#{params[:rabbit_port]}" ) }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('false') }
    it { is_expected.to contain_heat_config('DEFAULT/amqp_durable_queues').with_value(false) }
  end

  shared_examples_for 'rabbit without HA support (without backward compatibility)' do
    it 'configures rabbit' do
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_userid').with_value( params[:rabbit_userid] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_password').with_secret( true )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value(false)
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_version').with_ensure('absent')
    end
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_host').with_ensure('absent') }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_port').with_ensure('absent') }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') ) }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('false') }
    it { is_expected.to contain_heat_config('DEFAULT/amqp_durable_queues').with_value(false) }
  end

  shared_examples_for 'rabbit with HA support' do
    it 'configures rabbit' do
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_userid').with_value( params[:rabbit_userid] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_password').with_secret( true )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value(false)
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_version').with_ensure('absent')
    end
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_host').with_ensure('absent') }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_port').with_ensure('absent') }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') ) }
    it { is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('true') }
    it { is_expected.to contain_heat_config('DEFAULT/amqp_durable_queues').with_value(true) }
  end


  shared_examples_for 'qpid as rpc backend' do
    context("with default parameters") do
      it { is_expected.to contain_heat_config('DEFAULT/qpid_reconnect').with_value(true) }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_reconnect_timeout').with_value('0') }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_reconnect_limit').with_value('0') }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_reconnect_interval_min').with_value('0') }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_reconnect_interval_max').with_value('0') }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_reconnect_interval').with_value('0') }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_heartbeat').with_value('60') }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_protocol').with_value('tcp') }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_tcp_nodelay').with_value(true) }
      it { is_expected.to contain_heat_config('DEFAULT/amqp_durable_queues').with_value(false) }
    end

    context("with mandatory parameters set") do
      it { is_expected.to contain_heat_config('DEFAULT/rpc_backend').with_value('heat.openstack.common.rpc.impl_qpid') }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_hostname').with_value( params[:qpid_hostname] ) }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_port').with_value( params[:qpid_port] ) }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_username').with_value( params[:qpid_username]) }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_password').with_value(params[:qpid_password]) }
      it { is_expected.to contain_heat_config('DEFAULT/qpid_password').with_secret( true ) }
    end

    context("failing if the rpc_backend is not present") do
      before { params.delete( :rpc_backend) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end
  end

  shared_examples_for 'with SSL enabled with kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true,
        :kombu_ssl_ca_certs => '/path/to/ssl/ca/certs',
        :kombu_ssl_certfile => '/path/to/ssl/cert/file',
        :kombu_ssl_keyfile  => '/path/to/ssl/keyfile',
        :kombu_ssl_version  => 'TLSv1'
      )
    end

    it do
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_value('/path/to/ssl/ca/certs')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_value('/path/to/ssl/cert/file')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_value('/path/to/ssl/keyfile')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1')
    end
  end

  shared_examples_for 'with SSL enabled without kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true
      )
    end

    it do
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1')
    end
  end

  shared_examples_for 'with SSL disabled' do
    before do
      params.merge!(
        :rabbit_use_ssl     => false,
        :kombu_ssl_version  => 'TLSv1'
      )
    end

    it do
      is_expected.to contain_heat_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('false')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_heat_config('oslo_messaging_rabbit/kombu_ssl_version').with_ensure('absent')
    end
  end

  shared_examples_for 'with SSL wrongly configured' do
    before do
      params.merge!(
        :rabbit_use_ssl     => false
      )
    end

    context 'without required parameters' do

      context 'with rabbit_use_ssl => false and  kombu_ssl_ca_certs parameter' do
        before { params.merge!(:kombu_ssl_ca_certs => '/path/to/ssl/ca/certs') }
        it_raises 'a Puppet::Error', /The kombu_ssl_ca_certs parameter requires rabbit_use_ssl to be set to true/
      end

      context 'with rabbit_use_ssl => false and kombu_ssl_certfile parameter' do
        before { params.merge!(:kombu_ssl_certfile => '/path/to/ssl/cert/file') }
        it_raises 'a Puppet::Error', /The kombu_ssl_certfile parameter requires rabbit_use_ssl to be set to true/
      end

      context 'with rabbit_use_ssl => false and kombu_ssl_keyfile parameter' do
        before { params.merge!(:kombu_ssl_keyfile => '/path/to/ssl/keyfile') }
        it_raises 'a Puppet::Error', /The kombu_ssl_keyfile parameter requires rabbit_use_ssl to be set to true/
      end
    end

  end

  shared_examples_for 'with syslog disabled' do
    it { is_expected.to contain_heat_config('DEFAULT/use_syslog').with_value(false) }
  end

  shared_examples_for 'with syslog enabled' do
    before do
      params.merge!(
        :use_syslog => 'true'
      )
    end

    it do
      is_expected.to contain_heat_config('DEFAULT/use_syslog').with_value(true)
      is_expected.to contain_heat_config('DEFAULT/syslog_log_facility').with_value('LOG_USER')
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
      is_expected.to contain_heat_config('DEFAULT/use_syslog').with_value(true)
      is_expected.to contain_heat_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0')
    end
  end

  shared_examples_for 'with database_idle_timeout modified' do
    before do
      params.merge!(
        :database_idle_timeout => 69
      )
    end

    it do
      is_expected.to contain_heat_config('database/idle_timeout').with_value(69)
    end
  end

  shared_examples_for 'with ec2authtoken auth uri set' do
    before do
      params.merge!(
        :keystone_ec2_uri => 'http://1.2.3.4:35357/v2.0/ec2tokens'
      )
    end

    it do
      is_expected.to contain_heat_config('ec2authtoken/auth_uri').with_value('http://1.2.3.4:35357/v2.0/ec2tokens')
    end
  end

  shared_examples_for 'with auth uri set' do
    before do
      params.merge!(
        :auth_uri => 'http://1.2.3.4:35357/v2.0'
      )
    end

    it do
      is_expected.to contain_heat_config('keystone_authtoken/auth_uri').with_value('http://1.2.3.4:35357/v2.0')
    end
  end

  shared_examples_for 'with region_name set' do
    before do
      params.merge!(
        :region_name => "East",
      )
    end

    it 'has region_name set when specified' do
      is_expected.to contain_heat_config('DEFAULT/region_name_for_services').with_value('East')
    end
  end

  shared_examples_for 'without region_name set' do
    it 'doesnt have region_name set by default' do
      is_expected.to contain_heat_config('DEFAULT/region_name_for_services').with_enure('absent')
    end
  end

  shared_examples_for "with custom keystone identity_uri" do
    before do
      params.merge!({
        :identity_uri => 'https://foo.bar:1234/',
      })
    end
    it 'configures identity_uri' do
      is_expected.to contain_heat_config('keystone_authtoken/identity_uri').with_value("https://foo.bar:1234/");
    end
  end

  shared_examples_for "with custom keystone identity_uri and auth_uri" do
    before do
      params.merge!({
        :identity_uri => 'https://foo.bar:35357/',
        :auth_uri => 'https://foo.bar:5000/v2.0/',
      })
    end
    it 'configures identity_uri and auth_uri but deprecates old auth settings' do
      is_expected.to contain_heat_config('keystone_authtoken/identity_uri').with_value("https://foo.bar:35357/");
      is_expected.to contain_heat_config('keystone_authtoken/auth_uri').with_value("https://foo.bar:5000/v2.0/");
      is_expected.to contain_heat_config('keystone_authtoken/auth_port').with(:ensure => 'absent')
      is_expected.to contain_heat_config('keystone_authtoken/auth_protocol').with(:ensure => 'absent')
      is_expected.to contain_heat_config('keystone_authtoken/auth_host').with(:ensure => 'absent')
    end
  end

  shared_examples_for 'with instance_user set' do
    before do
      params.merge!(
        :instance_user => "fred",
      )
    end

    it 'has instance_user set when specified' do
      is_expected.to contain_heat_config('DEFAULT/instance_user').with_value('fred')
    end
  end

  shared_examples_for 'without instance_user set' do
    it 'doesnt have instance_user set by default' do
      is_expected.to contain_heat_config('DEFAULT/instance_user').with_enure('absent')
    end
  end

  shared_examples_for "with enable_stack_adopt and enable_stack_abandon set" do
    before do
      params.merge!({
        :enable_stack_adopt   => true,
        :enable_stack_abandon => true,
      })
    end
    it 'sets enable_stack_adopt and enable_stack_abandon' do
      is_expected.to contain_heat_config('DEFAULT/enable_stack_adopt').with_value(true);
      is_expected.to contain_heat_config('DEFAULT/enable_stack_abandon').with_value(true);
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
