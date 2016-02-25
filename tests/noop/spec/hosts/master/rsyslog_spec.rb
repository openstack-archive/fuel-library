require 'spec_helper'
require 'shared-examples'
manifest = 'master/rsyslog.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do

    let(:remote_log_file) do
      "#{Noop.variable 'rsyslog::params::rsyslog_d'}30-remote-log.conf"
    end

    it 'should correctly declare "rsyslog::server" class' do
      parameters = {
          :enable_tcp => true,
          :enable_udp => true,
          :server_dir => '/var/log/',
          :port => 514,
          :high_precision_timestamps => true,
      }
      is_expected.to contain_class('rsyslog::server').with parameters
    end

    it 'should correctly declare "openstack::logrotate" class' do
      parameters = {
          :role => 'server',
          :rotation => 'weekly',
          :keep => '4',
          :minsize => '10M',
          :maxsize => '20M',
      }
      is_expected.to contain_class('openstack::logrotate').with parameters
    end

    it 'should contain "rsyslog" fuel::systemd service with parameters' do
      parameters = {
          :start => true,
          :template_path => 'fuel/systemd/restart_template.erb',
          :config_name => 'restart.conf',
      }
      is_expected.to contain_fuel__systemd('rsyslog').with parameters
    end

    it 'should have the remote log config file' do
      is_expected.to contain_file(remote_log_file)
    end

  end
  run_test manifest
end
