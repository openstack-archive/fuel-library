# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'cluster/cluster.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:network_metadata) do
      Noop.hiera_hash('network_metadata')
    end

    let(:corosync_roles) do
      Noop.hiera('corosync_roles')
    end

    let(:corosync_nodes) do
      nodes = Noop.puppet_function 'get_nodes_hash_by_roles', network_metadata, corosync_roles
      Noop.puppet_function 'corosync_nodes', nodes, 'mgmt/corosync'
    end

    let(:cluster_recheck_interval) do
      Noop.hiera('cluster_recheck_interval', '190s')
    end

    it do
      parameters = {
          'cluster_recheck_interval' => cluster_recheck_interval,
          'cluster_nodes' => corosync_nodes,

      }
      is_expected.to contain_class('cluster').with(parameters)
    end



  end
  test_ubuntu_and_centos manifest
end
