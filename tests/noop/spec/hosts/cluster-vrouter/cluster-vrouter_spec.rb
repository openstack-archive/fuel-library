# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# HIERA: neut_vlan.ironic.controller
# HIERA: neut_vlan_l3ha.ceph.ceil-controller
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl

require 'spec_helper'
require 'shared-examples'
manifest = 'cluster-vrouter/cluster-vrouter.pp'

describe manifest do

  shared_examples 'catalog' do
    let(:endpoints) do
      Noop.hiera_hash('network_scheme', {}).fetch('endpoints', {})
    end

    it "should delcare cluster::vrouter_ocf with correct other_networks" do
      expect(subject).to contain_class('cluster::vrouter_ocf').with(
        'other_networks' => Noop.puppet_function('direct_networks', endpoints),
      )
    end

  end

  test_ubuntu_and_centos manifest
end

