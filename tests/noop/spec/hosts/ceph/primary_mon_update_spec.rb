require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/primary_mon_update.pp'

describe manifest do
  shared_examples 'catalog' do

    ceph_monitor_nodes = Noop.hiera_hash('ceph_monitor_nodes')
    mon_address_map = Noop.puppet_function 'get_node_to_ipaddr_map_by_network_role', ceph_monitor_nodes, 'ceph/public'
    mon_ips = mon_address_map.values.join(',')
    mon_hosts = mon_address_map.keys.join(',')

    storage_hash = Noop.hiera 'storage'

    if (storage_hash['volumes_ceph'] or
        storage_hash['images_ceph'] or
        storage_hash['objects_ceph'] or
        storage_hash['ephemeral_ceph']
       )

      it 'should add parameters to ceph.conf' do
        should contain_ceph_config('global/mon_host').with(:value => mon_ips)
        should contain_ceph_config('global/mon_initial_members').with(:value => mon_hosts)
      end
    end
  end
  test_ubuntu_and_centos manifest

end

