# ROLE: ceph-osd

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/ceph-osd.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera_hash 'storage'
    ceph_monitor_nodes = Noop.hiera 'ceph_monitor_nodes'
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
      if Noop.puppet4?
        args = Noop.nil2undef(osd_devices_hash)
      else
        args = osd_devices_hash
      end
      should contain_class('ceph::osds').with(
        'args' => args,
      )
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

