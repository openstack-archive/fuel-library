#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for ironic
#

require 'spec_helper'

describe 'ironic' do

  let :params do
    { :package_ensure              => 'present',
      :verbose                     => false,
      :debug                       => false,
      :enabled_drivers             => ['pxe_ipmitool'],
      :rabbit_host                 => '127.0.0.1',
      :rabbit_port                 => 5672,
      :rabbit_hosts                => false,
      :rabbit_userid               => 'guest',
      :rabbit_password             => 'guest',
      :rabbit_virtual_host         => '/',
      :database_connection         => 'sqlite:////var/lib/ironic/ironic.sqlite',
      :database_max_retries        => 10,
      :database_idle_timeout       => 3600,
      :database_reconnect_interval => 10,
      :database_retry_interval     => 10,
      :glance_num_retries          => 0,
      :glance_api_insecure         => false
    }
  end

  shared_examples_for 'ironic' do

    context 'and if rabbit_host parameter is provided' do
      it_configures 'a ironic base installation'
      it_configures 'with SSL disabled'
      it_configures 'with SSL enabled without kombu'
      it_configures 'with SSL enabled with kombu'
    end

    context 'and if rabbit_hosts parameter is provided' do
      before do
        params.delete(:rabbit_host)
        params.delete(:rabbit_port)
      end

      context 'with one server' do
        before { params.merge!( :rabbit_hosts => ['127.0.0.1:5672'] ) }
        it_configures 'a ironic base installation'
        it_configures 'rabbit HA with a single virtual host'
      end

      context 'with multiple servers' do
        before { params.merge!( :rabbit_hosts => ['rabbit1:5672', 'rabbit2:5672'] ) }
        it_configures 'a ironic base installation'
        it_configures 'rabbit HA with multiple hosts'
      end
    end

    context 'with mysql database backend' do
      before do
        params.merge!(:database_connection => 'mysql://ironic:ironic@localhost/ironic')
      end
    end

    context 'with sqlite database backend' do
      before do
        params.merge!(:database_connection => 'sqlite:////var/lib/ironic/ironic.sqlite')
      end
      it { is_expected.to contain_package('ironic-database-backend').with_name('python-pysqlite2')}
    end

    context 'with postgresql database backend' do
      before do
        params.merge!(:database_connection => 'postgresql://ironic:ironic@localhost/ironic')
      end
      it { is_expected.to contain_package('ironic-database-backend').with_name('python-psycopg2')}
    end

    it_configures 'with syslog disabled'
    it_configures 'with syslog enabled'
    it_configures 'with syslog enabled and custom settings'
  end

  shared_examples_for 'a ironic base installation' do

    it { is_expected.to contain_class('ironic::params') }

    it 'configures ironic configuration folder' do
      is_expected.to contain_file('/etc/ironic/').with(
        :ensure  => 'directory',
        :group   => 'ironic',
        :require => 'Package[ironic-common]'
      )
    end

    it 'configures ironic configuration file' do
      is_expected.to contain_file('/etc/ironic/ironic.conf').with(
        :group   => 'ironic',
        :require => 'Package[ironic-common]'
      )
    end

    it 'installs ironic package' do
      is_expected.to contain_package('ironic-common').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name],
        :tag    => 'openstack',
      )
    end

    it 'configures enabled_drivers' do
      is_expected.to contain_ironic_config('DEFAULT/enabled_drivers').with_value( params[:enabled_drivers] )
    end

    it 'configures credentials for rabbit' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_userid').with_value( params[:rabbit_userid] )
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_password').with_secret( true )
    end

    it 'should perform default database configuration' do
      is_expected.to contain_ironic_config('database/connection').with_value(params[:database_connection])
      is_expected.to contain_ironic_config('database/max_retries').with_value(params[:database_max_retries])
      is_expected.to contain_ironic_config('database/idle_timeout').with_value(params[:database_idle_timeout])
      is_expected.to contain_ironic_config('database/retry_interval').with_value(params[:database_retry_interval])
    end

    it 'configures glance connection' do
      is_expected.to contain_ironic_config('glance/glance_num_retries').with_value(params[:glance_num_retries])
      is_expected.to contain_ironic_config('glance/glance_api_insecure').with_value(params[:glance_api_insecure])
    end

    it 'configures ironic.conf' do
      is_expected.to contain_ironic_config('DEFAULT/verbose').with_value( params[:verbose] )
      is_expected.to contain_ironic_config('DEFAULT/auth_strategy').with_value('keystone')
      is_expected.to contain_ironic_config('DEFAULT/control_exchange').with_value('openstack')
    end
  end

  shared_examples_for 'rabbit HA with a single virtual host' do
    it 'in ironic.conf' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_host').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_port').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts] )
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value(true)
    end
  end

  shared_examples_for 'rabbit HA with multiple hosts' do
    it 'in ironic.conf' do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_host').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_port').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') )
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value(true)
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
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_value('/path/to/ssl/ca/certs')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_value('/path/to/ssl/cert/file')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_value('/path/to/ssl/keyfile')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1')
    end
  end

  shared_examples_for 'with SSL enabled without kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true,
      )
    end

    it do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1')
    end
  end

  shared_examples_for 'with SSL disabled' do
    before do
      params.merge!(
        :rabbit_use_ssl     => false,
        :kombu_ssl_ca_certs => 'undef',
        :kombu_ssl_certfile => 'undef',
        :kombu_ssl_keyfile  => 'undef',
        :kombu_ssl_version  => 'TLSv1'
      )
    end

    it do
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('false')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_ironic_config('oslo_messaging_rabbit/kombu_ssl_version').with_ensure('absent')
    end
  end


  shared_examples_for 'with amqp_durable_queues disabled' do
    it { is_expected.to contain_ironic_config('DEFAULT/amqp_durable_queues').with_value(false) }
  end

  shared_examples_for 'with amqp_durable_queues enabled' do
    before do
      params.merge( :amqp_durable_queues => true )
    end

    it { is_expected.to contain_ironic_config('DEFAULT/amqp_durable_queues').with_value(true) }
  end

  shared_examples_for 'with syslog disabled' do
    it { is_expected.to contain_ironic_config('DEFAULT/use_syslog').with_value(false) }
  end

  shared_examples_for 'with syslog enabled' do
    before do
      params.merge!( :use_syslog => true )
    end

    it do
      is_expected.to contain_ironic_config('DEFAULT/use_syslog').with_value(true)
      is_expected.to contain_ironic_config('DEFAULT/syslog_log_facility').with_value('LOG_USER')
    end
  end

  shared_examples_for 'with syslog enabled and custom settings' do
    before do
      params.merge!(
        :use_syslog    => true,
        :log_facility  => 'LOG_LOCAL0'
      )
    end

    it do
      is_expected.to contain_ironic_config('DEFAULT/use_syslog').with_value(true)
      is_expected.to contain_ironic_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0')
    end
  end

  shared_examples_for 'with one glance server' do
    before do
      params.merge!(:glance_api_servers => '10.0.0.1:9292')
    end

    it 'should configure one glance server' do
      is_expected.to contain_ironic_config('glance/glance_api_servers').with_value(p[:glance_api_servers])
    end
  end

  shared_examples_for 'with two glance servers' do
    before do
      params.merge!(:glance_api_servers => ['10.0.0.1:9292','10.0.0.2:9292'])
    end

    it 'should configure one glance server' do
       is_expected.to contain_ironic_config('glance/glance_api_servers').with_value(p[:glance_api_servers].join(','))
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :common_package_name => 'ironic-common' }
    end

    it_configures 'ironic'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :common_package_name => 'openstack-ironic-common' }
    end

    it_configures 'ironic'
  end
end
