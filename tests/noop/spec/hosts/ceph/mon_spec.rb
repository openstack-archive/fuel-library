# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/mon.pp'

describe manifest do
  shared_examples 'catalog' do

    storage_hash = Noop.hiera 'storage'

    let(:mon_key) do
      Noop.hiera_structure 'storage/mon_key', 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
    end

    let(:bootstrap_osd_key) do
      Noop.hiera_structure 'storage/bootstrap_osd_key', 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A=='
    end

    let(:admin_key) do
      Noop.hiera_structure 'storage/admin_key', 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
    end

    let(:fsid) do
      Noop.hiera_structure 'storage/fsid', '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'
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

    let(:osd_pool_default_min_size) do
      '1'
    end

    let(:osd_journal_size) do
      '2048'
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

    ceph_monitor_nodes = Noop.hiera_hash('ceph_monitor_nodes')
    mon_address_map = Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ceph_monitor_nodes, 'ceph/public'
    ceph_primary_monitor_node = Noop.hiera_hash('ceph_primary_monitor_node')
    primary_mon = Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ceph_primary_monitor_node, 'ceph/public'
    mon_ips = mon_address_map.values.join(',')
    mon_hosts = mon_address_map.keys.join(',')
    primary_mon_ip = primary_mon.values.join
    primary_mon_hostname = primary_mon.keys.join

    if (storage_hash['volumes_ceph'] or
        storage_hash['images_ceph'] or
        storage_hash['objects_ceph'] or
        storage_hash['ephemeral_ceph']
       )
      describe 'should configure primary ceph mon' do
        let(:facts) {
          Noop.ubuntu_facts.merge({
            :hostname => primary_mon.keys[0]
          })
        }

        it 'should deploy primary ceph mon' do
          should contain_class('ceph').with(
            'fsid'                      => fsid,
            'mon_initial_members'       => primary_mon_hostname,
            'mon_host'                  => primary_mon_ip,
            'cluster_network'           => ceph_cluster_network,
            'public_network'            => ceph_public_network,
            'osd_pool_default_size'     => osd_pool_default_size,
            'osd_pool_default_pg_num'   => osd_pool_default_pg_num,
            'osd_pool_default_pgp_num'  => osd_pool_default_pgp_num,
            'osd_pool_default_min_size' => osd_pool_default_min_size,
            'osd_journal_size'          => osd_journal_size,
          )
        end
      end

      describe 'should configure non-primary ceph mon' do
        let(:facts) {
          Noop.ubuntu_facts.merge({
            :hostname => 'non-primary-node'
          })
        }

        it 'should deploy non-primary ceph mon' do
          should contain_class('ceph').with(
            'fsid'                      => fsid,
            'mon_initial_members'       => mon_hosts,
            'mon_host'                  => mon_ips,
            'cluster_network'           => ceph_cluster_network,
            'public_network'            => ceph_public_network,
            'osd_pool_default_size'     => osd_pool_default_size,
            'osd_pool_default_pg_num'   => osd_pool_default_pg_num,
            'osd_pool_default_pgp_num'  => osd_pool_default_pgp_num,
            'osd_pool_default_min_size' => osd_pool_default_min_size,
            'osd_journal_size'          => osd_journal_size,
          )
        end
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
          'secret'         => admin_key,
          'cap_mon'        => 'allow *',
          'cap_osd'        => 'allow *',
          'cap_mds'        => 'allow',
          'inject'         => true,
        )
      end

      it 'should add bootstrap osd key' do
        should contain_ceph__key('client.bootstrap-osd').with(
          'secret'  => bootstrap_osd_key,
          'cap_mon' => 'allow profile bootstrap-osd',
        )
      end

      if storage_hash['volumes_ceph']
        it { should contain_service('cinder-volume').that_subscribes_to('Class[ceph]') }
        it { should contain_service('cinder-backup').that_subscribes_to('Class[ceph]') }
      end

      if storage_hash['images_ceph']
        it { should contain_service('glance-api').that_subscribes_to('Class[ceph]') }
      end
    end
  end

  test_ubuntu_and_centos manifest
end

