require 'spec_helper'
require 'shared-examples'
manifest = 'roles/compute.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do

    host_uuid = Noop.hiera 'host_uuid'

    network_metadata     = Noop.hiera 'network_metadata'
    memcache_server_port = Noop.hiera 'memcache_server_port', '22122'

    let (:memcache_servers) do
      "127.0.0.1:#{memcache_server_port}"
    end

    let(:nova_hash) do
      Noop.hiera_structure 'nova'
    end

    let(:rhost_mem) do
      { 'reserved_host_memory' => [[Float(facts[:memorysize_mb]).floor * 0.2, 512].max, 1536].min }
    end

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

    it 'should configure libvirt host_uuid' do
      should contain_augeas('libvirt-conf-uuid').with(
        :context => '/files/etc/libvirt/libvirtd.conf',
        :changes => "set host_uuid #{host_uuid}"
      ).that_notifies('Service[libvirt]')
    end

    # libvirt/qemu with(out) selinux/apparmor
    it 'libvirt/qemu config should have proper security_driver and apparmor configuration' do
      if facts[:osfamily] == 'RedHat'
        should contain_file_line('qemu_selinux').with(
          'path' => '/etc/libvirt/qemu.conf',
          'line' => 'security_driver = "selinux"',
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
        'value' => 'volumev2:cinderv2:internalURL'
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
    xit 'nova config should contain right memcached servers list' do
      should contain_nova_config('keystone_authtoken/memcached_servers').with(
        'value' => memcache_servers,
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
    management_vip = Noop.hiera('management_vip')
    glance_api_servers = "#{management_vip}:9292"
    vncproxy_protocol = 'https'

    if Noop.hiera_structure('use_ssl')
      vncproxy_host = Noop.hiera_structure('use_ssl/nova_public_hostname')
      glance_protocol = 'https'
      glance_endpoint = Noop.hiera_structure('use_ssl/glance_internal_hostname')
      glance_api_servers = "#{glance_protocol}://#{glance_endpoint}:9292"
    elsif Noop.hiera_structure('public_ssl/services')
      vncproxy_host = Noop.hiera_structure('public_ssl/hostname')
    else
      vncproxy_host = Noop.hiera('public_vip')
      vncproxy_protocol = 'http'
    end

    it 'should properly configure vncproxy with (non-)ssl' do
      should contain_class('openstack::compute').with(
        'vncproxy_host' => vncproxy_host
      )
      should contain_class('nova::compute').with(
        'vncproxy_protocol' => vncproxy_protocol
      )
    end

    it 'should properly configure glance api servers with (non-)ssl' do
      should contain_class('openstack::compute').with(
        'glance_api_servers' => glance_api_servers
      )
    end

    # Check out nova config params
    it 'should properly configure nova' do
      node_name = Noop.hiera('node_name')
      network_metadata = Noop.hiera_hash('network_metadata')
      roles = network_metadata['nodes'][node_name]['node_roles']
      nova_hash.merge!({'vncproxy_protocol' => vncproxy_protocol})

      if roles.include? 'ceph-osd'
        nova_compute_rhostmem = rhost_mem['reserved_host_memory']
      else
        rhost_mem['reserved_host_memory'] = :undef
        nova_compute_rhostmem = 512 # default
      end

      should contain_class('openstack::compute').with(
        'nova_hash' => rhost_mem.merge(nova_hash)
      )
      should contain_class('nova::compute').with(
        'reserved_host_memory' => nova_compute_rhostmem
      )
    end
  end

  test_ubuntu_and_centos manifest
end


