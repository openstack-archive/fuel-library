require 'spec_helper'

describe 'openstack::compute' do

  before :each do
    Puppet::Parser::Functions.newfunction(:is_pkg_installed, :type => :rvalue) {
      |args| true
    }
  end

  let(:default_params) { {
    :internal_address   => nil,
    :rpc_backend         => 'rabbit',
    :amqp_hosts          => false,
    :amqp_user           => 'nova',
    :amqp_password       => 'rabbit_pw',
    :rabbit_ha_queues    => false,
    :glance_api_servers  => 'undef',
    :libvirt_type        => 'kvm',
    :vncproxy_host       => false,
    :vncserver_listen    => '0.0.0.0',
    :migration_support   => nil,
    :enabled             => true,
    :nova_hash             => {},
    :verbose               => false,
    :debug                 => false,
    :ssh_private_key       => '/var/lib/astute/nova/nova',
    :ssh_public_key        => '/var/lib/astute/nova/nova.pub',
    :cache_server_ip       => ['127.0.0.1'],
    :cache_server_port     => '11211',
    :use_syslog            => false,
    :use_stderr            => true,
    :syslog_log_facility   => 'LOG_LOCAL6',
    :nova_report_interval  => '10',
    :nova_service_down_time => '60',
    :state_path            => '/var/lib/nova',
    :storage_hash          => {},
    :compute_driver        => 'libvirt.LibvirtDriver',
    :config_drive_format   => nil,
  } }

  let(:params) { {} }

  shared_examples_for 'compute configuration' do
    let :p do
      default_params.merge(params)
    end


    context 'with a default config' do

      let :params do
        { :internal_address   => '127.0.0.1',
          :amqp_hosts         => '127.0.0.1:55555',
          :glance_api_servers => 'localhost:9292',
        }
      end

      it 'contains openstack::compute' do
        should contain_class('openstack::compute')
      end

      it 'configures with the default params' do
        if facts[:os_package_type] == 'debian' or facts[:osfamily] == 'RedHat'
          libvirt_service_name = 'libvirtd'
        else
          libvirt_service_name = 'libvirt-bin'
        end
        host_uuid = facts[:libvirt_uuid]
        should contain_class('nova').with(
          :install_utilities => false,
          :ensure_package    => 'present',
          :rpc_backend       => p[:rpc_backend],
          :rabbit_hosts      => [ params[:amqp_hosts] ],
          :rabbit_userid     => p[:amqp_user],
          :rabbit_password   => p[:amqp_password],
          :kombu_reconnect_delay => '5.0',
          :image_service     => 'nova.image.glance.GlanceImageService',
          :glance_api_servers => p[:glance_api_servers],
          :verbose           => p[:verbose],
          :debug             => p[:debug],
          :use_syslog        => p[:use_syslog],
          :use_stderr        => p[:use_stderr],
          :log_facility      => p[:syslog_log_facility],
          :state_path        => p[:state_path],
          :report_interval   => p[:nova_report_interval],
          :service_down_time => p[:nova_service_down_time],
          :notify_on_state_change => 'vm_and_task_state',
          :memcached_servers => ['127.0.0.1:11211'],
        )
        should contain_class('nova::availability_zone').with(
          :default_availability_zone => '<SERVICE DEFAULT>',
          :default_schedule_zone     => '<SERVICE DEFAULT>',
        )
        should contain_class('nova::compute').with(
          :ensure_package => 'present',
          :enabled        => p[:enabled],
          :vncserver_proxyclient_address => p[:internal_address],
          :vncproxy_host  => p[:vncproxy_host],
          :vncproxy_port  => '6080',
          :force_config_drive => false,
          :neutron_enabled => true,
          :network_device_mtu => '65000',
          :instance_usage_audit => true,
          :instance_usage_audit_period => 'hour',
          :default_schedule_zone => nil,
          :config_drive_format => p[:config_drive_format]
        )
        should contain_class('nova::compute::libvirt').with(
          :libvirt_virt_type    => p[:libvirt_type],
          :vncserver_listen     => p[:vncserver_listen],
          :migration_suport     => p[:migration_support],
          :remove_unused_original_minimum_age_seconds => '86400',
          :compute_driver       => p[:compute_driver],
          :libvirt_service_name => libvirt_service_name,
        )
        should contain_augeas('libvirt-conf-uuid').with(
          :context => '/files/etc/libvirt/libvirtd.conf',
          :changes => ["set host_uuid #{host_uuid}"],
        ).that_notifies('Service[libvirt]')
        if facts[:osfamily] == 'RedHat'
          should contain_file_line('qemu_selinux')
          should contain_package('device-mapper-multipath')
        elsif facts[:osfamily] == 'Debian'
          should contain_file_line('qemu_apparmor')
          should contain_file_line('apparmor_libvirtd')
          should contain_package('multipath-tools')
        end
        should contain_class('nova::client')
        should contain_install_ssh_keys('nova_ssh_key_for_migration')
        should contain_file('/var/lib/nova/.ssh/config')

        if facts[:operatingsystem] == 'Ubuntu'
          should contain_package('cpufrequtils').with(
            :ensure => 'present'
          )
          should contain_file('/etc/default/cpufrequtils').with(
            :content => "GOVERNOR=\"performance\"\n",
            :require => 'Package[cpufrequtils]',
            :notify  => 'Service[cpufrequtils]',
          )
          should contain_service('cpufrequtils').with(
            :ensure => 'running',
            :enable => true,
            :status => '/bin/true',
          )
        end
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      {
        :osfamily           => 'Debian',
        :operatingsystem    => 'Ubuntu',
        :hostname           => 'hostname.example.com',
        :openstack_version  => { 'nova' => 'present' },
        :os_service_default => '<SERVICE DEFAULT>',
        :os_package_type    => 'debian',
        :libvirt_uuid       => '370d7c4c19b84f4ab34f213764e4663d',
      }
    end

    it_configures 'compute configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      {
        :osfamily           => 'RedHat',
        :operatingsystem    => 'CentOS',
        :hostname           => 'hostname.example.com',
        :openstack_version  => { 'nova' => 'present' },
        :os_service_default => '<SERVICE DEFAULT>',
        :os_package_type    => 'rpm',
        :operatingsystemmajrelease => '7',
        :libvirt_uuid       => '370d7c4c19b84f4ab34f213764e4663d',
      }
    end

    it_configures 'compute configuration'
  end

end

