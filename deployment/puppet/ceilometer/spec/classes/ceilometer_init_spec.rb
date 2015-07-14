require 'spec_helper'

describe 'ceilometer' do

  let :params do
    {
      :metering_secret    => 'metering-s3cr3t',
      :package_ensure     => 'present',
      :debug              => 'False',
      :log_dir            => '/var/log/ceilometer',
      :verbose            => 'False',
    }
  end

  let :rabbit_params do
    {
      :rabbit_host        => '127.0.0.1',
      :rabbit_port        => 5672,
      :rabbit_userid      => 'guest',
      :rabbit_password    => '',
      :rabbit_virtual_host => '/',
    }
  end

  let :qpid_params do
    {
      :rpc_backend   => "ceilometer.openstack.common.rpc.impl_qpid",
      :qpid_hostname => 'localhost',
      :qpid_port     => 5672,
      :qpid_username => 'guest',
      :qpid_password  => 'guest',
    }
  end

  shared_examples_for 'ceilometer' do

    context 'with rabbit_host parameter' do
      before { params.merge!( rabbit_params ) }
      it_configures 'a ceilometer base installation'
      it_configures 'rabbit with SSL support'
      it_configures 'rabbit without HA support (with backward compatibility)'
    end

    context 'with rabbit_hosts parameter' do
      context 'with one server' do
        before { params.merge!( rabbit_params ).merge!( :rabbit_hosts => ['127.0.0.1:5672'] ) }
        it_configures 'a ceilometer base installation'
        it_configures 'rabbit with SSL support'
        it_configures 'rabbit without HA support (without backward compatibility)'
      end

      context 'with multiple servers' do
        before { params.merge!( rabbit_params ).merge!( :rabbit_hosts => ['rabbit1:5672', 'rabbit2:5672'] ) }
        it_configures 'a ceilometer base installation'
        it_configures 'rabbit with SSL support'
        it_configures 'rabbit with HA support'
      end
    end

    context 'with qpid' do
      before {params.merge!( qpid_params ) }
      it_configures 'a ceilometer base installation'
      it_configures 'qpid support'
    end

  end

  shared_examples_for 'a ceilometer base installation' do

    it { is_expected.to contain_class('ceilometer::params') }

    it 'configures ceilometer group' do
      is_expected.to contain_group('ceilometer').with(
        :name    => 'ceilometer',
        :require => 'Package[ceilometer-common]'
      )
    end

    it 'configures ceilometer user' do
      is_expected.to contain_user('ceilometer').with(
        :name    => 'ceilometer',
        :gid     => 'ceilometer',
        :system  => true,
        :require => 'Package[ceilometer-common]'
      )
    end

    it 'configures ceilometer configuration folder' do
      is_expected.to contain_file('/etc/ceilometer/').with(
        :ensure  => 'directory',
        :owner   => 'ceilometer',
        :group   => 'ceilometer',
        :mode    => '0750',
        :require => 'Package[ceilometer-common]'
      )
    end

    it 'configures ceilometer configuration file' do
      is_expected.to contain_file('/etc/ceilometer/ceilometer.conf').with(
        :owner   => 'ceilometer',
        :group   => 'ceilometer',
        :mode    => '0640',
        :require => 'Package[ceilometer-common]'
      )
    end

    it 'installs ceilometer common package' do
      is_expected.to contain_package('ceilometer-common').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name],
        :tag    => 'openstack'
      )
    end

    it 'configures required metering_secret' do
      is_expected.to contain_ceilometer_config('publisher/metering_secret').with_value('metering-s3cr3t')
      is_expected.to contain_ceilometer_config('publisher/metering_secret').with_value( params[:metering_secret] ).with_secret(true)
    end

    context 'without the required metering_secret' do
      before { params.delete(:metering_secret) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    it 'configures debug and verbosity' do
      is_expected.to contain_ceilometer_config('DEFAULT/debug').with_value( params[:debug] )
      is_expected.to contain_ceilometer_config('DEFAULT/verbose').with_value( params[:verbose] )
    end

    it 'configures logging directory by default' do
      is_expected.to contain_ceilometer_config('DEFAULT/log_dir').with_value( params[:log_dir] )
    end

    context 'with logging directory disabled' do
      before { params.merge!( :log_dir => false) }

      it { is_expected.to contain_ceilometer_config('DEFAULT/log_dir').with_ensure('absent') }
    end

    it 'configures notification_topics' do
      is_expected.to contain_ceilometer_config('DEFAULT/notification_topics').with_value('notifications')
    end

    it 'configures syslog to be disabled by default' do
      is_expected.to contain_ceilometer_config('DEFAULT/use_syslog').with_value('false')
    end

    context 'with syslog enabled' do
      before { params.merge!( :use_syslog => 'true' ) }

      it { is_expected.to contain_ceilometer_config('DEFAULT/use_syslog').with_value('true') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
    end

    context 'with syslog enabled and custom settings' do
      before { params.merge!(
       :use_syslog   => 'true',
       :log_facility => 'LOG_LOCAL0'
      ) }

      it { is_expected.to contain_ceilometer_config('DEFAULT/use_syslog').with_value('true') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0') }
    end

    context 'with overriden notification_topics parameter' do
      before { params.merge!( :notification_topics => ['notifications', 'custom']) }

      it 'configures notification_topics' do
        is_expected.to contain_ceilometer_config('DEFAULT/notification_topics').with_value('notifications,custom')
      end
    end
  end

  shared_examples_for 'rabbit without HA support (with backward compatibility)' do

    it 'configures rabbit' do
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_userid').with_value( params[:rabbit_userid] )
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] ).with_secret(true)
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
    end

    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_host').with_value( params[:rabbit_host] ) }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_port').with_value( params[:rabbit_port] ) }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_hosts').with_value( "#{params[:rabbit_host]}:#{params[:rabbit_port]}" ) }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('false') }

  end

  shared_examples_for 'rabbit without HA support (without backward compatibility)' do

    it 'configures rabbit' do
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_userid').with_value( params[:rabbit_userid] )
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] ).with_secret(true)
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
    end

    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_host').with_ensure('absent') }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_port').with_ensure('absent') }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') ) }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('false') }

  end

  shared_examples_for 'rabbit with HA support' do

    it 'configures rabbit' do
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_userid').with_value( params[:rabbit_userid] )
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] ).with_secret(true)
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
    end

    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_host').with_ensure('absent') }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_port').with_ensure('absent') }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') ) }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('true') }

  end

  shared_examples_for 'rabbit with SSL support' do
    context "with default parameters" do
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('false') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_version').with_ensure('absent') }
    end

    context "with SSL enabled with kombu" do
      before { params.merge!(
        :rabbit_use_ssl     => 'true',
        :kombu_ssl_ca_certs => '/path/to/ca.crt',
        :kombu_ssl_certfile => '/path/to/cert.crt',
        :kombu_ssl_keyfile  => '/path/to/cert.key',
        :kombu_ssl_version  => 'TLSv1'
      ) }

      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_value('/path/to/ca.crt') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_value('/path/to/cert.crt') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_value('/path/to/cert.key') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1') }
    end

    context "with SSL enabled without kombu" do
      before { params.merge!(
        :rabbit_use_ssl     => 'true'
      ) }

      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1') }
    end

    context "with SSL wrongly configured" do
      context 'with kombu_ssl_ca_certs parameter' do
        before { params.merge!(:kombu_ssl_ca_certs => '/path/to/ca.crt') }
        it_raises 'a Puppet::Error', /The kombu_ssl_ca_certs parameter requires rabbit_use_ssl to be set to true/
      end

      context 'with kombu_ssl_certfile parameter' do
        before { params.merge!(:kombu_ssl_certfile => '/path/to/ssl/cert/file') }
        it_raises 'a Puppet::Error', /The kombu_ssl_certfile parameter requires rabbit_use_ssl to be set to true/
      end

      context 'with kombu_ssl_keyfile parameter' do
        before { params.merge!(:kombu_ssl_keyfile => '/path/to/ssl/keyfile') }
        it_raises 'a Puppet::Error', /The kombu_ssl_keyfile parameter requires rabbit_use_ssl to be set to true/
      end
    end
  end

  shared_examples_for 'qpid support' do
    context("with default parameters") do
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_reconnect').with_value(true) }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_reconnect_timeout').with_value('0') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_reconnect_limit').with_value('0') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_reconnect_interval_min').with_value('0') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_reconnect_interval_max').with_value('0') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_reconnect_interval').with_value('0') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_heartbeat').with_value('60') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_protocol').with_value('tcp') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_tcp_nodelay').with_value(true) }
    end

    context("with mandatory parameters set") do
      it { is_expected.to contain_ceilometer_config('DEFAULT/rpc_backend').with_value('ceilometer.openstack.common.rpc.impl_qpid') }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_hostname').with_value( params[:qpid_hostname] ) }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_port').with_value( params[:qpid_port] ) }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_username').with_value( params[:qpid_username]) }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_password').with_value(params[:qpid_password]) }
      it { is_expected.to contain_ceilometer_config('DEFAULT/qpid_password').with_value( params[:qpid_password] ).with_secret(true) }
    end

    context("failing if the rpc_backend is not present") do
      before { params.delete( :rpc_backend) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :common_package_name => 'ceilometer-common' }
    end

    it_configures 'ceilometer'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :common_package_name => 'openstack-ceilometer-common' }
    end

    it_configures 'ceilometer'
  end
end
