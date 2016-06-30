# ROLE: compute

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

    kombu_compression    = Noop.hiera 'kombu_compression', ''
    ironic_enabled       = Noop.hiera_structure 'ironic/enabled'

    let(:facts) {
      Noop.ubuntu_facts.merge({
        :libvirt_uuid        => '0251bf3e0a3f48da8cdf8daad5473a7f',
        :allocated_hugepages => '{"1G":true,"2M":true}',
      })
    }

    let (:memcached_servers) { Noop.hiera 'memcached_servers' }

    let(:nova_hash) do
      Noop.hiera_structure 'nova'
    end

    let(:compute_hash) do
      Noop.hiera_hash 'compute', {}
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

    let(:nova_report_interval) { Noop.hiera 'nova_report_interval', '60' }
    let(:nova_service_down_time) { Noop.hiera 'nova_service_down_time', '180' }


    let(:global_debug) { Noop.hiera 'debug', 'true' }
    let(:debug) { Noop.puppet_function 'pick', compute_hash['debug'], global_debug }
    let(:config_drive_format) { Noop.puppet_function 'pick', compute_hash['config_drive_format'], 'vfat' }
    let(:log_facility) { Noop.hiera 'syslog_log_facility_nova', 'LOG_LOCAL6' }

    let(:use_cache) { Noop.puppet_function 'pick', nova_hash['use_cache'], true }


    # Legacy openstack-compute tests

    if ironic_enabled
      compute_driver = 'ironic.IronicDriver'
    else
      compute_driver = 'libvirt.LibvirtDriver'
    end

    it 'should explicitly disable libvirt_inject_partition for compute node' do
      libvirt_inject_partition = '-2'
      should contain_class('nova::compute::libvirt').with(
        'libvirt_inject_partition' => libvirt_inject_partition,
      )
    end

    it 'should force instances to have config drives' do
        should contain_class('nova::compute').with(
            'force_config_drive' => true
        )
    end

    it 'should enable migration support for libvirt with vncserver listen on 0.0.0.0' do
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
    it 'should configure listen_tls in libvirtd.conf' do
      should contain_file_line('/etc/libvirt/libvirtd.conf listen_tls').with(
        'path'  => '/etc/libvirt/libvirtd.conf',
        'line'  => 'listen_tls = 0',
        'match' => 'listen_tls =',
      )
    end

    it 'should configure listen_tcp in libvirtd.conf' do
      should contain_file_line('/etc/libvirt/libvirtd.conf listen_tcp').with(
        'path'  => '/etc/libvirt/libvirtd.conf',
        'line'  => 'listen_tcp = 1',
        'match' => 'listen_tcp =',
      )
    end

    it 'should configure auth_tcp in libvirtd.conf' do
      should contain_file_line('/etc/libvirt/libvirtd.conf auth_tcp').with(
        'path'  => '/etc/libvirt/libvirtd.conf',
        'line'  => 'auth_tcp = "none"',
        'match' => 'auth_tcp =',
      )
    end

    it 'should configure libvirt host_uuid' do
      host_uuid = facts[:libvirt_uuid]
      should contain_augeas('libvirt-conf-uuid').with(
        'context' => '/files/etc/libvirt/libvirtd.conf',
        'changes' => "set host_uuid #{host_uuid}"
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
    let(:allocated_hugepages) { Noop.puppet_function 'parsejson', facts[:allocated_hugepages] }
    let(:use_1g_huge_pages) { allocated_hugepages['1G'] }
    let(:use_2m_huge_pages) { allocated_hugepages['2M'] }

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
        if use_1g_huge_pages
          hugepages_1g_opts_ensure = 'present'
          should contain_file('/mnt/hugepages_1GB').with(
            'ensure'  => 'directory',
            'owner'   => 'root',
            'group'   => 'kvm',
            'require' => 'Package[qemu-kvm]',
          )
          should contain_exec('mount_hugetlbfs_1g').with(
            'command' => 'mount -t hugetlbfs hugetlbfs-kvm -o mode=775,gid=kvm,pagesize=1GB /mnt/hugepages_1GB',
            'unless'  => 'grep -q /mnt/hugepages_1GB /proc/mounts',
            'path'    => '/usr/sbin:/usr/bin:/sbin:/bin',
            'require' => 'File[/mnt/hugepages_1GB]',
          )
          if use_2m_huge_pages
            libvirt_hugetlbfs_mount = 'hugetlbfs_mount = ["/run/hugepages/kvm", "/mnt/hugepages_1GB"]'
            qemu_hugepages_value    = 'set KVM_HUGEPAGES 1'
          else
            libvirt_hugetlbfs_mount = 'hugetlbfs_mount = "/mnt/hugepages_1GB"'
            qemu_hugepages_value    = 'rm KVM_HUGEPAGES'
          end
        else
          qemu_hugepages_value     = 'set KVM_HUGEPAGES 1'
          libvirt_hugetlbfs_mount  = 'hugetlbfs_mount = "/run/hugepages/kvm"'
          hugepages_1g_opts_ensure = 'absent'
        end
      else
        qemu_hugepages_value     = 'rm KVM_HUGEPAGES'
        libvirt_hugetlbfs_mount  = 'hugetlbfs_mount = ""'
        hugepages_1g_opts_ensure = 'absent'
      end

      if facts[:osfamily] == 'Debian'
        should contain_augeas('qemu_hugepages').with(
          'context' => '/files/etc/default/qemu-kvm',
          'changes' => qemu_hugepages_value,
        ).that_notifies('Service[libvirt]')

        should contain_file_line('libvirt_hugetlbfs_mount').with(
          'path'    => '/etc/libvirt/qemu.conf',
          'line'    => libvirt_hugetlbfs_mount,
          'match'   => '^hugetlbfs_mount =.*$',
          'require' => 'Package[libvirt-bin]',
        ).that_notifies('Service[libvirt]')

        should contain_file_line('libvirt_1g_hugepages_apparmor').with(
          'path'    => '/etc/apparmor.d/abstractions/libvirt-qemu',
          'after'   => 'owner "/run/hugepages/kvm/libvirt/qemu/',
          'line'    => '  owner "/mnt/hugepages_1GB/libvirt/qemu/**" rw,',
          'require' => 'Package[libvirt-bin]',
          'ensure'  => hugepages_1g_opts_ensure,
        ).that_notifies('Exec[refresh_apparmor]')

        should contain_file_line('1g_hugepages_fstab').with(
          'path'    => '/etc/fstab',
          'line'    => 'hugetlbfs-kvm /mnt/hugepages_1GB hugetlbfs mode=775,gid=kvm,pagesize=1GB 0 0',
          'ensure'  => hugepages_1g_opts_ensure,
        )

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

    libvirt_type = Noop.hiera 'libvirt_type', nil

    it 'should set permissions for /dev/kvm under Ubuntu' do
      if facts[:operatingsystem] == 'Ubuntu' and libvirt_type == 'kvm'
        should contain_file('/dev/kvm').with(
          :ensure => 'present',
          :group  => 'kvm',
          :mode   => '0660',
        )
        should contain_service('qemu-kvm').that_comes_before('File[/dev/kvm]')
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
    it 'nova config should have report_interval' do
      should contain_nova_config('DEFAULT/report_interval').with(
        'value' => nova_report_interval,
      )
    end
    it 'nova config should have service_down_time' do
      should contain_nova_config('DEFAULT/service_down_time').with(
        'value' => nova_service_down_time,
      )
    end
    it 'nova config should have use_stderr set to false' do
      should contain_nova_config('DEFAULT/use_stderr').with(
        'value' => 'false',
      )
    end
    it 'nova config should contain right memcached servers list' do
      should contain_nova_config('keystone_authtoken/memcached_servers').with(
        'value' => memcached_servers.join(','),
      )
    end

    it 'should configure nova cache correctly' do
      should contain_class('nova::cache').with(
        :enabled          => use_cache,
        :backend          => 'oslo_cache.memcache_pool',
        :memcache_servers => memcache_servers.split(','),
      )
    end

    it 'should install fping for nova API extension' do
      should contain_package('fping').with('ensure' => 'present')
    end

    it 'nova config should have config_drive_format set to vfat' do
      should contain_nova_config('DEFAULT/config_drive_format').with(
        'value' => config_drive_format
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
    vncproxy_protocol = 'https'
    ssl_hash = Noop.hiera_hash 'use_ssl', {}

    let(:glance_endpoint_default) { Noop.hiera 'glance_endpoint', management_vip }
    let(:glance_protocol) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance','internal','protocol','http' }
    let(:glance_endpoint) { Noop.puppet_function 'get_ssl_property',ssl_hash,{},'glance','internal','hostname', glance_endpoint_default}
    let(:glance_api_servers) { Noop.hiera 'glance_api_servers', "#{glance_protocol}://#{glance_endpoint}:9292" }

    if !ssl_hash.empty?
      vncproxy_host = Noop.hiera_structure('use_ssl/nova_public_hostname')
    elsif Noop.hiera_structure('public_ssl/services')
      vncproxy_host = Noop.hiera_structure('public_ssl/hostname')
    else
      vncproxy_host = Noop.hiera('public_vip')
      vncproxy_protocol = 'http'
    end

    let(:vncproxy_port) { Noop.puppet_function 'pick', nova_hash['vncproxy_port'], '6080' }

    it 'should properly configure vncproxy with (non-)ssl' do
      should contain_class('nova::compute').with(
        'vncproxy_protocol' => vncproxy_protocol,
        'vncproxy_host'     => vncproxy_host,
        'vncproxy_port'     => vncproxy_port,
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

    it 'should configure logging when debug is enabled' do
      if debug
        default_log_levels = {
          'oslo.messaging' => 'DEBUG',
        }

        should contain_class('nova::logging').with(
          'default_log_levels' => default_log_levels,
        )
      end
    end

    # Check out nova config params
    it 'should properly configure nova' do

      node_name = Noop.hiera('node_name')
      network_metadata = Noop.hiera_hash('network_metadata')
      roles = network_metadata['nodes'][node_name]['node_roles']

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

    let(:default_availability_zone) { Noop.puppet_function 'pick', nova_hash['default_availability_zone'], facts[:os_service_default] }
    let(:default_schedule_zone) { Noop.puppet_function 'pick', nova_hash['default_schedule_zone'], facts[:os_service_default] }

    it 'should configure availability zones' do
      should contain_class('nova::availability_zone').with(
        'default_availability_zone' => default_availability_zone,
        'default_schedule_zone'     => default_schedule_zone,
      )
    end

    it 'configures with the default params' do

      should contain_class('nova').with(
        'debug'            => debug,
        'log_facility'     => log_facility,
        'state_path'       => nova_hash['state_path'],
        'notify_on_state_change' => 'vm_and_task_state',
      )
      should contain_class('nova::compute').with(
        'enabled'                     => 'false',
        'instance_usage_audit'        => 'true',
        'instance_usage_audit_period' => 'hour',
        'config_drive_format'         => 'vfat'
      )

      min_age = Noop.puppet_function 'pick', nova_hash['remove_unused_original_minimum_age_seconds'], '86400'
      should contain_class('nova::compute::libvirt').with(
        'libvirt_virt_type'    => libvirt_type,
        'vncserver_listen'     => '0.0.0.0',
        'remove_unused_original_minimum_age_seconds' => min_age,
      )
    end

    it 'should contain migration basics' do
      should contain_class('nova::client')
      should contain_install_ssh_keys('nova_ssh_key_for_migration')
      should contain_file('/var/lib/nova/.ssh/config')
    end

    it 'should contain cpufrequtils' do
      if facts[:operatingsystem] == 'Ubuntu'
        should contain_package('cpufrequtils').with(
          'ensure' => 'present'
        )
        should contain_file('/etc/default/cpufrequtils').with(
          'content' => "GOVERNOR=\"performance\"\n",
          'require' => 'Package[cpufrequtils]',
          'notify'  => 'Service[cpufrequtils]',
        )
        should contain_service('cpufrequtils').with(
          'ensure' => 'running',
          'enable' => 'true',
          'status' => '/bin/true',
        )
      end
    end

    it 'should configure kombu compression' do
      kombu_compression = Noop.hiera 'kombu_compression', facts[:os_service_default]
      should contain_nova_config('oslo_messaging_rabbit/kombu_compression').with(:value => kombu_compression)
    end
  end

  it 'should contain ssh and multipath packages' do
    if facts[:osfamily] == 'Debian'
      packages = ['openssh-client', 'multipath-tools']
    elsif facts[:osfamily] == 'RedHat'
      packages = ['openssh-clients', 'device-mapper-multipath']
    end
    packages.each do |p|
      should contain_package(p)
    end
  end

  test_ubuntu_and_centos manifest
end


