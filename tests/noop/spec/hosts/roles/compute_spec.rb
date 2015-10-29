require 'spec_helper'
require 'shared-examples'
manifest = 'roles/compute.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:nova_hash) do
      Noop.hiera_structure 'nova'
    end

    let(:rhost_mem) do
      { 'reserved_host_memory' => 1536 }
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

    # SSL support
    public_ssl = Noop.hiera_structure('public_ssl/services')

    if public_ssl
      vncproxy_protocol = 'https'
      vncproxy_host = Noop.hiera_structure('public_ssl/hostname')
    else
      vncproxy_protocol = 'http'
      vncproxy_host = Noop.hiera('public_vip')
    end

    it 'should properly configure vncproxy with (non-)ssl' do
      should contain_class('openstack::compute').with(
        'vncproxy_host' => vncproxy_host
      )
      should contain_class('nova::compute').with(
        'vncproxy_protocol' => vncproxy_protocol
      )
    end

    # Check out nova config params
    it 'should properly configure nova' do
      node_name = Noop.hiera('node_name')
      network_metadata = Noop.hiera_structure('network_metadata')
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


