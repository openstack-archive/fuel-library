require 'spec_helper'

describe 'openstack::compute' do

  let(:default_params) { {
    :internal_address   => nil,
    :nova_user_password => nil,
    :database_connection => false,
    :purge_nova_config   => false,
    :queue_proider       => 'rabbitmq',
    :rpc_backend         => 'nova.openstack.common.rpc.impl_kombu',
    :amqp_hosts          => false,
    :amqp_user           => 'nova',
    :amqp_password       => 'rabbit_pw',
    :rabbit_ha_queues    => false,
    :glance_api_servers  => 'undef',
    :libvirt_type        => 'kvm',
    :host_uuid           => nil,
    :vnc_enabled         => true,
    :vncproxy_host       => false,
    :vncserver_listen    => '0.0.0.0',
    :migration_support   => nil,
    :enabled             => true,
    :use_vcenter          => false,
    :auto_assign_floating_ip => false,
    :network_config          => [],
    :public_interface        => nil,
    :private_interface       => nil,
    :network_manage          => nil,
    :fixed_range             => 'undef',
    :network_provider        => 'nova',
    :neutron_integration_bridge => 'br-int',
    :neutron_user_password => 'asdf1234',
    :base_mac              => 'fa:16:3e:00:00:00',
    :ceilometer_user_password => 'ceilometer_pass',
    :nova_hash             => {},
    :verbose               => false,
    :debug                 => false,
    :service_endpoint      => '127.0.0.1',
    :ssh_private_key       => '/var/lib/astute/nova/nova',
    :ssh_public_key        => '/var/lib/astute/nova/nova.pub',
    :cache_server_ip       => ['127.0.0.1'],
    :cache_server_port     => '11211',
    :manage_volumnes       => false,
    :nv_physical_volume    => nil,
    :cinder_volume_group   => 'cinder-volumes',
    :cinder                => true,
    :cinder_user_password  => 'cinder_user_pass',
    :cinder_db_password    => 'cinder_db_pass',
    :cinder_db_user        => 'cinder',
    :cinder_db_dbname      => 'cinder',
    :cinder_iscsi_bind_addr => false,
    :db_host               => '127.0.0.1',
    :use_syslog            => false,
    :use_stderr            => true,
    :syslog_log_facility   => 'LOG_LOCAL6',
    :syslog_log_facility_neutron => 'LOG_LOCAL4',
    :syslog_log_facility_ceilometer => 'LOG_LOCAL0',
    :nova_rate_limites     => 'undef',
    :nova_report_interval  => '10',
    :nova_service_down_time => '60',
    :cinder_rate_limites   => nil,
    :create_networks       => false,
    :state_path            => '/var/lib/nova',
    :ceilometer            => false,
    :ceilometer_metering_secret => 'ceilometer',
    :libvirt_vif_driver    => 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
    :storage_hash          => {},
    :neutron_settings      => {},
    :install_bridge_utils  => false,
    :compute_driver        => 'libvirt.LibvirtDriver',
    :config_drive_formate  => nil,
  } }

  let(:params) { {} }

  shared_examples_for 'compute configuration' do
    let :p do
      default_params.merge(params)
    end


    context 'with a default config' do
      let :params do
        { :internal_address   => '127.0.0.1',
          :nova_user_password => 'password',
          :public_interface   => 'eth0',
          :private_interface  => 'eth1',
          :network_manager    => 'something',
          :amqp_hosts         => '127.0.0.1:55555',
          :glance_api_servers => 'localhost:9292',
        }
      end

      it 'contains openstack::compute' do
        should contain_class('openstack::compute')
      end

      it 'configures with the default params' do
        should contain_class('nova').with(
          :install_utilities => false,
          :ensure_package    => 'present',
          :database_backend  => p[:database_backend],
          :rpc_backend       => p[:rpc_backend],
          :rabbit_hosts      => [ params[:amqp_hosts] ],
          :rabbit_userid     => p[:amqp_user],
          :rabbit_password   => p[:amqp_password],
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
          :memcached_servers => ['127.0.0.1:11211']
        )
        should contain_class('nova::compute').with(
          :ensure_package => 'present',
          :enabled        => p[:enabled],
          :vnc_enabled    => p[:vnc_enabled],
          :vncserver_proxyclient_address => p[:internal_address],
          :vncproxy_host  => p[:vncproxy_host],
          :vncproxy_port  => '6080',
          :force_config_drive => false,
          :neutron_enabled => false,
          :install_bridge_utils => p[:install_bridge_utils],
          :instance_usage_audit => true,
          :instance_usage_audit_period => 'hour',
          :default_availability_zone => 'nova',
          :default_schedule_zone => nil,
          :config_drive_format => p[:config_drive_format]
        )
        should contain_class('nova::compute::libvirt').with(
          :libvirt_virt_type    => p[:libvirt_type],
          :vncserver_listen     => p[:vncserver_listen],
          :migration_suport     => p[:migration_support],
          :remove_unused_original_minimum_age_seconds => '86400',
          :compute_driver       => p[:compute_driver],
          :libvirt_service_name => 'libvirtd'
        )
        should contain_augeas('libvirt-conf-uuid').with(
          :context => '/files/etc/libvirt/libvirtd.conf',
          :changes => "set host_uuid #{p[:host_uuid]}"
        ).that_notifies('Service[libvirt]')
        if facts[:osfamily] == 'RedHat'
          should contain_file_line('qemu_selinux')
        elsif facts[:osfamily] == 'Debian'
          should contain_file_line('qemu_apparmor')
          should contain_file_line('apparmor_libvirtd')
        end
        should contain_class('nova::client')
        should contain_install_ssh_keys('nova_ssh_key_for_migration')
        should contain_file('/var/lib/nova/.ssh/config')
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com',
        :openstack_version => {'nova' => 'present' }
      }
    end

    it_configures 'compute configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :hostname => 'hostname.example.com',
        :openstack_version => {'nova' => 'present' }
      }
    end

    it_configures 'compute configuration'
  end

end

