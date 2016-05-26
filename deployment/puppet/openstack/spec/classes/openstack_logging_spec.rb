require 'spec_helper'

describe 'openstack::logging' do

  let(:default_params) { {
    :role => 'client',
    :log_remote => true,
    :log_local => false,
    :log_auth_local => false,
    :rotation => 'daily',
    :keep => '7',
    :minsize => '10M',
    :maxsize => '100M',
    :rservers => [{'remote_type'=>'udp', 'server'=>'master', 'port'=>'514'},],
    :port => 514,
    :proto => 'udp',
    :show_timezone => false,
    :virtual => false,
    :rabbit_log_level => 'NOTICE',
    :production => 'prod',
    :escapenewline => false,
    :debug => false,
  } }

  let(:params) { {} }

  shared_examples_for 'logging configuration' do
    let :p do
      default_params.merge(params)
    end

    it 'contains openstack::logging' do
      should contain_class('openstack::logging')
    end

    context 'with default params' do
      it 'configures with the default params' do
        should_not contain_class('openstack::checksum_udp')
        should contain_class('rsyslog::params')
        should contain_rsyslog__imfile('04-rabbitmq')
        should contain_rsyslog__imfile('04-rabbitmq-sasl')
        should contain_rsyslog__imfile('04-rabbitmq-startup_err')
        should contain_rsyslog__imfile('04-rabbitmq-startup_log')
        should contain_rsyslog__imfile('04-rabbitmq-shutdown_err')
        should contain_rsyslog__imfile('04-rabbitmq-shutdown_log')
        should contain_rsyslog__imfile('05-apache2-error')
        should contain_rsyslog__imfile('11-horizon_access')
        should contain_rsyslog__imfile('11-horizon_error')
        should contain_rsyslog__imfile('12-keystone_wsgi_admin_access')
        should contain_rsyslog__imfile('12-keystone_wsgi_admin_error')
        should contain_rsyslog__imfile('13-keystone_wsgi_main_access')
        should contain_rsyslog__imfile('13-keystone_wsgi_main_error')
        should contain_rsyslog__imfile('61-mco_agent_debug')
        ['10-nova',
         '20-keystone',
         '30-cinder',
         '40-glance',
         '50-default',
         '50-neutron',
         '51-ceilometer',
         '53-aodh',
         '55-murano',
         '54-heat',
         '02-ha',
         '03-dashboard',
         '04-mysql',
         '60-puppet-apply',
         '61-mco-nailgun-agent',
         '62-mongod',
         '80-swift',
         '90-local',
         '00-remote',].each do |item|
           should contain_file("/etc/rsyslog.d/#{item}.conf")
        end
        should contain_class('rsyslog::client').with(
          :log_remote                => false,
          :high_precision_timestamps => p[:show_timezone]
        )
        should contain_rsyslog__snippet('00-disable-EscapeControlCharactersOnReceive')
      end
    end

    context 'with role = server' do
      let :params do
        { :role => 'server' }
      end

      it 'configures server' do
        should contain_firewall("#{p[:port]} #{p[:proto]} rsyslog")
        should contain_class('rsyslog::server').with(
          :server_dir                => '/var/log/',
          :high_precision_timestamps => p[:show_timezone],
          :port                      => p[:port]
        )
        should contain_file('/etc/rsyslog.d/30-remote-log.conf')
        should contain_class('openstack::logrotate').with(
          :role     => p[:role],
          :rotation => p[:rotation],
          :keep     => p[:keep],
          :minsize  => p[:minsize],
          :maxsize  => p[:maxsize],
          :debug    => p[:debug]
        )
        should contain_rsyslog__snippet('00-disable-EscapeControlCharactersOnReceive')
      end
    end
    context 'with virtual = true' do
      let :params do
        { :virtual => true }
      end
      it 'with virtual = true' do
        should contain_class('openstack::checksum_udp').with(:port => p[:port])
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com',
        :rsyslog_version => '7.4.4',
      }
    end

    it_configures 'logging configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com',
        :rsyslog_version => '5.8.10',
        :operatingsystemmajrelease => '7.0',
      }
    end

    it_configures 'logging configuration'
  end

end

