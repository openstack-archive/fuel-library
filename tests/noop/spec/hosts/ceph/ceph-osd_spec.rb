# ROLE: ceph-osd

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/ceph-osd.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:facts) {
      Noop.ubuntu_facts.merge({
        :osd_devices_list => '/dev/sdb'
      })
    }

    storage_hash = Noop.hiera 'storage'

    let(:osd_devices_hash) do
      Noop.puppet_function 'osd_devices_hash', '/dev/sdb'
    end

    let(:admin_key) do
      Noop.hiera_structure 'storage/admin_key', 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
    end

    let(:bootstrap_osd_key) do
      Noop.hiera_structure 'storage/bootstrap_osd_key', 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A=='
    end

    let(:fsid) do
      Noop.hiera_structure 'storage/fsid', '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'
    end

    let(:network_scheme) do
      Noop.hiera_hash 'network_scheme'
    end

    let(:prepare_network_config) do
      Noop.puppet_function 'prepare_network_config', network_scheme
    end

    let(:ceph_cluster_network) do
      Noop.puppet_function 'get_network_role_property', 'ceph/replication', 'network'
    end

    let(:ceph_public_network) do
      Noop.puppet_function 'get_network_role_property', 'ceph/public', 'network'
    end

    let(:ceph_monitor_nodes) do
      Noop.hiera_hash('ceph_monitor_nodes')
    end

    let(:mon_address_map) do
      Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ceph_monitor_nodes, 'ceph/public'
    end

    let(:mon_host) do
      mon_address_map.values.join(',')
    end

    let(:mon_initial_members) do
      mon_address_map.keys.join(',')
    end

    let(:osd_pool_default_size) do
      storage_hash['osd_pool_size']
    end

    let(:osd_pool_default_pg_num) do
      storage_hash['pg_num']
    end

    let(:osd_pool_default_pgp_num) do
      storage_hash['pg_num']
    end

    if storage_hash['debug']
      debug = storage_hash['debug']
    else
     debug = Noop.hiera 'debug', true
    end

    ceph_tuning_settings = Noop.hiera 'ceph_tuning_settings'

    it 'should configure ceph' do
      should contain_class('ceph').with(
        'fsid'                      => fsid,
        'mon_initial_members'       => mon_initial_members,
        'mon_host'                  => mon_host,
        'cluster_network'           => ceph_cluster_network,
        'public_network'            => ceph_public_network,
        'osd_pool_default_size'     => osd_pool_default_size,
        'osd_pool_default_pg_num'   => osd_pool_default_pg_num,
        'osd_pool_default_pgp_num'  => osd_pool_default_pgp_num,
        'osd_pool_default_min_size' => '1',
        'osd_journal_size'          => '2048',
      )
    end

    it 'should add parameters to ceph.conf' do
      should contain_ceph_config('global/osd_mkfs_type').with(:value => 'xfs')
      should contain_ceph_config('global/filestore_xattr_use_omap').with(:value => true)
      should contain_ceph_config('global/osd_recovery_max_active').with(:value => '1')
      should contain_ceph_config('global/osd_max_backfills').with(:value => '1')
      should contain_ceph_config('client/rbd_cache_writethrough_until_flush').with(:value => true)
      should contain_ceph_config('client/rbd_cache').with(:value => true)
      should contain_ceph_config('global/log_to_syslog').with(:value => true)
      should contain_ceph_config('global/log_to_syslog_level').with(:value => 'info')
      should contain_ceph_config('global/log_to_syslog_facility').with(:value => 'LOG_LOCAL0')
    end

    it 'should add admin key' do
      should contain_ceph__key('client.admin').with(
        'secret'  => admin_key,
        'cap_mon' => 'allow *',
        'cap_osd' => 'allow *',
        'cap_mds' => 'allow',
        'inject'  => false,
      )
    end

    it 'should add osd bootstrap key' do
      should contain_ceph__key('client.bootstrap-osd').with(
        'keyring_path' => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
        'secret'       => bootstrap_osd_key,
        'inject'       => false,
      )
    end

    it 'should configure osd disks' do
      should contain_class('ceph::osds').with(
        'args' => osd_devices_hash,
      )
    end

    it 'should start osd daemons' do
      should contain_service('ceph-osd-all-starter').with(
        'ensure'   => 'running',
        'provider' => 'upstart',
      ).that_requires('Class[ceph::osds]')
    end

    if ceph_tuning_settings != {}
      it 'should set Ceph tuning settings' do
        should contain_ceph_config('global/debug_default').with(:value => debug)
        should contain_ceph_config('global/max_open_files').with(:value => ceph_tuning_settings['max_open_files'])
        should contain_ceph_config('osd/osd_mkfs_type').with(:value => ceph_tuning_settings['osd_mkfs_type'])
        should contain_ceph_config('osd/osd_mount_options_xfs').with(:value => ceph_tuning_settings['osd_mount_options_xfs'])
        should contain_ceph_config('osd/osd_op_threads').with(:value => ceph_tuning_settings['osd_op_threads'])
        should contain_ceph_config('osd/filestore_queue_max_ops').with(:value => ceph_tuning_settings['filestore_queue_max_ops'])
        should contain_ceph_config('osd/filestore_queue_committing_max_ops').with(:value => ceph_tuning_settings['filestore_queue_committing_max_ops'])
        should contain_ceph_config('osd/journal_max_write_entries').with(:value => ceph_tuning_settings['journal_max_write_entries'])
        should contain_ceph_config('osd/journal_queue_max_ops').with(:value => ceph_tuning_settings['journal_queue_max_ops'])
        should contain_ceph_config('osd/objecter_inflight_ops').with(:value => ceph_tuning_settings['objecter_inflight_ops'])
        should contain_ceph_config('osd/filestore_queue_max_bytes').with(:value => ceph_tuning_settings['filestore_queue_max_bytes'])
        should contain_ceph_config('osd/filestore_queue_committing_max_bytes').with(:value => ceph_tuning_settings['filestore_queue_committing_max_bytes'])
        should contain_ceph_config('osd/journal_max_write_bytes').with(:value => ceph_tuning_settings['journal_max_write_bytes'])
        should contain_ceph_config('osd/journal_queue_max_bytes').with(:value => ceph_tuning_settings['journal_queue_max_bytes'])
        should contain_ceph_config('osd/ms_dispatch_throttle_bytes').with(:value => ceph_tuning_settings['ms_dispatch_throttle_bytes'])
        should contain_ceph_config('osd/objecter_infilght_op_bytes').with(:value => ceph_tuning_settings['objecter_infilght_op_bytes'])
        should contain_ceph_config('osd/filestore_max_sync_interval').with(:value => ceph_tuning_settings['filestore_max_sync_interval'])
      end
    end
  end
  test_ubuntu_and_centos manifest
end

