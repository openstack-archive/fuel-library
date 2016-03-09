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
    memcache_roles       = Noop.hiera 'memcache_roles'
    memcache_addresses   = Noop.hiera 'memcached_addresses', false
    memcache_server_port = Noop.hiera 'memcache_server_port', '11211'

    ironic_enabled       = Noop.hiera_structure 'ironic/enabled'

    let(:memcache_nodes) do
      Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, memcache_roles
    end

    let(:memcache_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', memcache_nodes, 'mgmt/memcache'
    end

    let (:memcache_servers) do
      if not memcache_addresses
        memcache_address_map.values.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
      else
        memcache_addresses.map { |server| "#{server}:#{memcache_server_port}" }.join(",")
      end
    end

    let(:nova_hash) do
      Noop.hiera_structure 'nova'
    end

    let(:storage_hash) do
      Noop.hiera_structure 'storage'
    end

    let(:rhost_mem) do
      { 'reserved_host_memory' => [[Float(facts[:memorysize_mb]).floor * 0.2, 512].max, 1536].min }
    end

    let(:network_scheme) do
      Noop.hiera_hash('network_scheme', {})
    end

    let(:prepare) do
      Noop.puppet_function('prepare_network_config', network_scheme)
    end

    let(:nic_passthrough_whitelist) do
      prepare
      Noop.puppet_function('get_nic_passthrough_whitelist', 'sriov')
    end

    # Legacy openstack-compute tests

    if ironic_enabled
      compute_driver = 'ironic.IronicDriver'
    else
      compute_driver = 'libvirt.LibvirtDriver'
    end

    it 'should configure libvirt_inject_partition for compute node' do
      if storage_hash && (storage_hash['ephemeral_ceph'] || storage_hash['volumes_ceph'])
        libvirt_inject_partition = '-2'
      elsif facts[:operatingsystem] == 'CentOS'
        libvirt_inject_partition = '-1'
      else
        should contain_k_mod('nbd').with('ensure' => 'present')

        should contain_file_line('nbd_on_boot').with(
          'path' => '/etc/modules',
          'line' => 'nbd',
        )
        libvirt_inject_partition = '1'
      end
      should contain_class('nova::compute::libvirt').with(
        'libvirt_inject_partition' => libvirt_inject_partition,
      )
    end

    it 'should enable migration support for libvirt with vncserver listen on 0.0.0.0' do
      should contain_class('nova::compute::libvirt').with('migration_support' => true)
      should contain_class('nova::compute::libvirt').with('vncserver_listen' => '0.0.0.0')
      should contain_class('nova::migration::libvirt')
    end

    it 'nova config should have proper compute_driver' do
      should contain_nova_config('DEFAULT/compute_driver').with(:value => 'libvirt.LibvirtDriver')
    end

    it 'should declare class nova::compute with neutron_enabled set to true' do
      should contain_class('nova::compute').with(
        'neutron_enabled' => true,
      )
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

    it 'should install qemu-kvm package' do
      should contain_package('qemu-kvm').with('ensure' => 'present')
    end

    enable_dpdk = Noop.hiera_structure 'dpdk/enabled', false
    if enable_dpdk
      network_device_mtu = false
    else
      network_device_mtu = 65000
    end
    it 'should configure network_device_mtu for nova-compute' do
      should contain_class('nova::compute').with(
        'network_device_mtu' => network_device_mtu
      )
    end

    let(:node_hash) { Noop.hiera_hash 'node' }
    let(:enable_hugepages) { node_hash.fetch('nova_hugepages_enabled', false) }
    let(:enable_cpu_pinning) { node_hash.fetch('nova_cpu_pinning_enabled', false) }

    it 'should configure vcpu_pin_set for nova' do
      if enable_cpu_pinning
        vcpu_pin_set = Noop.hiera_structure 'nova/cpu_pinning', false
        should contain_class('nova::compute').with(
          'vcpu_pin_set' => vcpu_pin_set
        )
      end
    end

    it 'should set up huge pages support for qemu-kvm' do
      if enable_hugepages
        qemu_hugepages_value = 'set KVM_HUGEPAGES 1'
      else
        qemu_hugepages_value = 'rm KVM_HUGEPAGES'
      end

      if facts[:osfamily] == 'Debian'
        should contain_augeas('qemu_hugepages').with(
          'context' => '/files/etc/default/qemu-kvm',
          'changes' => qemu_hugepages_value,
        ).that_notifies('Service[libvirt]')

        should contain_augeas('qemu_hugepages').that_notifies('Service[qemu-kvm]')
        should contain_service('qemu-kvm').that_comes_before('Service[libvirt]')
      end
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
    it 'nova config should contain right memcached servers list' do
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
      should contain_class('nova::compute').with(
        'vncproxy_protocol' => vncproxy_protocol
        'vncproxy_host'     => vncproxy_host
        'vncproxy_port'     => vncproxy_port
      )
    end

    it 'should properly configure glance api servers with (non-)ssl' do
      should contain_class('nova').with(
        'glance_api_servers' => glance_api_servers
      )
    end

    enable_sriov = Noop.hiera_structure 'quantum_settings/supported_pci_vendor_devs', false
    it 'should pass pci_passthrough_whitelist to nova::compute' , :if => enable_sriov do
      pci_passthrough_json = Noop.puppet_function 'nic_whitelist_to_json', nic_passthrough_whitelist
      should contain_class('nova::compute').with('pci_passthrough' => pci_passthrough_json)
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

      should contain_class('nova::compute').with(
        'reserved_host_memory' => nova_compute_rhostmem
      )
    end
  end

  it 'configures with the default params' do
    if facts[:os_package_type] == 'debian' or facts[:osfamily] == 'RedHat'
      libvirt_service_name = 'libvirtd'
    else
      libvirt_service_name = 'libvirt-bin'
    end
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
      :vnc_enabled    => p[:vnc_enabled],
      :vncserver_proxyclient_address => p[:internal_address],
      :vncproxy_host  => p[:vncproxy_host],
      :vncproxy_port  => '6080',
      :force_config_drive => false,
      :neutron_enabled => false,
      :install_bridge_utils => p[:install_bridge_utils],
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
      :changes => ["set host_uuid #{p[:host_uuid]}"],
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

  test_ubuntu_and_centos manifest
end


