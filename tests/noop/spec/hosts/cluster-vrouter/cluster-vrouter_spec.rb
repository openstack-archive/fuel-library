# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu

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

