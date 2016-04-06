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

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'])
      it { should contain_class('ceph').with(
           'mon_hosts'                => ceph_monitor_nodes.keys,
           'osd_pool_default_size'    => storage_hash['osd_pool_size'],
           'osd_pool_default_pg_num'  => storage_hash['pg_num'],
           'osd_pool_default_pgp_num' => storage_hash['pg_num'],
           'ephemeral_ceph'           => storage_hash['ephemeral_ceph'],
           )
         }

      if ceph_tuning_settings
        it 'should set Ceph tuning settings' do
          should contain_ceph_conf('global/debug_default').with(:value => debug)
          should contain_ceph_conf('global/max_open_files').with(:value => ceph_tuning_settings['max_open_files'])
          should contain_ceph_conf('osd/osd_mkfs_type').with(:value => ceph_tuning_settings['osd_mkfs_type'])
          should contain_ceph_conf('osd/osd_mount_options_xfs').with(:value => ceph_tuning_settings['osd_mount_options_xfs'])
          should contain_ceph_conf('osd/osd_op_threads').with(:value => ceph_tuning_settings['osd_op_threads'])
          should contain_ceph_conf('osd/filestore_queue_max_ops').with(:value => ceph_tuning_settings['filestore_queue_max_ops'])
          should contain_ceph_conf('osd/filestore_queue_committing_max_ops').with(:value => ceph_tuning_settings['filestore_queue_committing_max_ops'])
          should contain_ceph_conf('osd/journal_max_write_entries').with(:value => ceph_tuning_settings['journal_max_write_entries'])
          should contain_ceph_conf('osd/journal_queue_max_ops').with(:value => ceph_tuning_settings['journal_queue_max_ops'])
          should contain_ceph_conf('osd/objecter_inflight_ops').with(:value => ceph_tuning_settings['objecter_inflight_ops'])
          should contain_ceph_conf('osd/filestore_queue_max_bytes').with(:value => ceph_tuning_settings['filestore_queue_max_bytes'])
          should contain_ceph_conf('osd/filestore_queue_committing_max_bytes').with(:value => ceph_tuning_settings['filestore_queue_committing_max_bytes'])
          should contain_ceph_conf('osd/journal_max_write_bytes').with(:value => ceph_tuning_settings['journal_max_write_bytes'])
          should contain_ceph_conf('osd/journal_queue_max_bytes').with(:value => ceph_tuning_settings['journal_queue_max_bytes'])
          should contain_ceph_conf('osd/ms_dispatch_throttle_bytes').with(:value => ceph_tuning_settings['ms_dispatch_throttle_bytes'])
          should contain_ceph_conf('osd/objecter_infilght_op_bytes').with(:value => ceph_tuning_settings['objecter_infilght_op_bytes'])
          should contain_ceph_conf('osd/filestore_max_sync_interval').with(:value => ceph_tuning_settings['filestore_max_sync_interval'])
        end
      end
    end
  end

  test_ubuntu_and_centos manifest
end

