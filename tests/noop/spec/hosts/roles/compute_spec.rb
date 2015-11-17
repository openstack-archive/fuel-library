require 'spec_helper'
require 'shared-examples'
manifest = 'roles/compute.pp'

describe manifest do
  shared_examples 'catalog' do

    # Libvirtd.conf
    it 'should configure listen_tls, listen_tcp and auth_tcp in libvirtd.conf' do
      should contain_augeas('libvirt-conf').with(
        'context' => '/files/etc/libvirt/libvirtd.conf',
        'changes' => [
          'set listen_tls 0',
          'set listen_tcp 1',
          'set auth_tcp none',
        ],
      )
    end

    # libvirt/qemu with(out) selinux/apparmor
    it 'libvirt/qemu config should have proper security_driver and apparmor configuration' do
      if facts[:osfamily] == 'RedHat'
        should contain_file_line('no_qemu_selinux').with(
          'path' => '/etc/libvirt/qemu.conf',
          'line' => 'security_driver = "none"',
        ).that_notifies('Service[libvirt]')
      elsif facts[:osfamily] == 'Debian'
        should contain_file_line('qemu_apparmor').with(
          'path' => '/etc/libvirt/qemu.conf',
          'line' => 'security_driver = "apparmor"',
        ).that_notifies('Service[libvirt]')
        should contain_file_line('apparmor_libvirtd').with(
          'path' => '/etc/apparmor.d/usr.sbin.libvirtd',
          'line' => "#  unix, # shouldn't be used for libvirt/qemu",
        )
        should contain_exec('refresh_apparmor').that_subscribes_to('File_line[apparmor_libvirtd]')
      end
    end

    let(:configuration_override) do
      Noop.hiera_structure 'configuration'
    end

    let(:nova_config_override_resources) do
      configuration_override.fetch('nova_config', {})
    end

    let(:nova_paste_api_ini_override_resources) do
      configuration_override.fetch('nova_paste_api_ini', {})
    end

    # Nova.config options
    it 'nova config should have proper live_migration_flag' do
      should contain_nova_config('libvirt/live_migration_flag').with(
        'value' => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST',
      )
    end
    it 'nova config should have proper block_migration_flag' do
      should contain_nova_config('libvirt/block_migration_flag').with(
        'value' => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_NON_SHARED_INC',
      )
    end
    it 'nova config should have proper catalog_info' do
      should contain_nova_config('cinder/catalog_info').with(
        'value' => 'volume:cinder:internalURL'
      )
    end
    it 'nova config should have proper use_syslog_rfc_format' do
      should contain_nova_config('DEFAULT/use_syslog_rfc_format').with(
        'value' => 'true',
      )
    end
    it 'nova config should have proper connection_type' do
      should contain_nova_config('DEFAULT/connection_type').with(
        'value' => 'libvirt',
      )
    end
    it 'nova config should have proper allow_resize_to_same_host' do
      should contain_nova_config('DEFAULT/allow_resize_to_same_host').with(
        'value' => 'true',
      )
    end
    it 'nova config should have report_interval set to 60' do
      should contain_nova_config('DEFAULT/report_interval').with(
        'value' => '60',
      )
    end
    it 'nova config should have service_down_time set to 180' do
      should contain_nova_config('DEFAULT/service_down_time').with(
        'value' => '180',
      )
    end
    it 'nova config should have use_stderr set to false' do
      should contain_nova_config('DEFAULT/use_stderr').with(
        'value' => 'false',
      )
    end

    it 'should install fping for nova API extension' do
      should contain_package('fping').with('ensure' => 'present')
    end

    it 'nova config should have config_drive_format set to vfat' do
      should contain_nova_config('DEFAULT/config_drive_format').with(
        'value' => 'vfat'
      )
    end

    it 'nova config should not have database connection' do
      should_not contain_nova_config('database/connection')
    end

    it 'nova config should be modified by override_resources' do
       is_expected.to contain_override_resources('nova_config').with(:data => nova_config_override_resources)
    end

    it 'should use override_resources to update nova_config' do
      ral_catalog = Noop.create_ral_catalog self
      nova_config_override_resources.each do |title, params|
        params['value'] = 'True' if params['value'].is_a? TrueClass
        expect(ral_catalog).to contain_nova_config(title).with(params)
      end
    end

    it 'nova_paste_api_ini should be modified by override_resources' do
      is_expected.to contain_override_resources('nova_paste_api_ini').with(:data => nova_paste_api_ini_override_resources)
    end

    it 'should use override_resources to update nova_paste_api_ini' do
      ral_catalog = Noop.create_ral_catalog self
      nova_paste_api_ini_override_resources.each do |title, params|
       params['value'] = 'True' if params['value'].is_a? TrueClass
       expect(ral_catalog).to contain_nova_paste_api_ini(title).with(params)
      end
    end


    # SSL support
    if Noop.hiera_structure('use_ssl')
      context 'with enabled and overridden TLS' do
        it 'should properly configure vncproxy WITH ssl' do
          vncproxy_host = Noop.hiera_structure('use_ssl/nova_public_hostname')
          should contain_class('openstack::compute').with(
            'vncproxy_host' => vncproxy_host
          )
          should contain_class('nova::compute').with(
            'vncproxy_protocol' => 'https'
          )
        end
        it 'should properly configure glance api servers WITH ssl' do
          glance_protocol = 'https'
          glance_endpoint = Noop.hiera_structure('use_ssl/glance_internal_hostname')
          glance_api_servers = "#{glance_protocol}://#{glance_endpoint}:9292"
          should contain_class('openstack::compute').with(
            'glance_api_servers' => glance_api_servers
          )
        end
      end
    elsif Noop.hiera_structure('public_ssl/services')
      context 'with enabled and not overridden TLS' do
        it 'should properly configure vncproxy WITH ssl' do
          vncproxy_host = Noop.hiera_structure('public_ssl/hostname')
          should contain_class('openstack::compute').with(
            'vncproxy_host' => vncproxy_host
          )
          should contain_class('nova::compute').with(
            'vncproxy_protocol' => 'https'
          )
        end
        it 'should properly configure glance api servers WITHOUT ssl' do
          management_vip = Noop.hiera('management_vip')
          should contain_class('openstack::compute').with(
            'glance_api_servers' => "#{management_vip}:9292"
          )
        end
      end
    else
      it 'should properly configure vncproxy WITHOUT ssl' do
        vncproxy_host = Noop.hiera('public_vip')
        should contain_class('openstack::compute').with(
          'vncproxy_host' => vncproxy_host
        )
        should contain_class('nova::compute').with(
          'vncproxy_protocol' => 'http'
        )
      end
      it 'should properly configure glance api servers WITHOUT ssl' do
        management_vip = Noop.hiera('management_vip')
        should contain_class('openstack::compute').with(
          'glance_api_servers' => "#{management_vip}:9292"
        )
      end
    end

  end

  test_ubuntu_and_centos manifest
end


