# RUN: neut_tun.ceph.murano.sahara.ceil-mongo ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-cinder ubuntu
# RUN: neut_tun.ironic-ironic ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-ceph-osd ubuntu
# RUN: neut_vlan.ceph-ceph-osd ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-compute ubuntu
# RUN: neut_vlan.ceph-compute ubuntu
# RUN: neut_vlan.murano.sahara.ceil-compute ubuntu
# R_N: neut_gre.generate_vms ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'cgroups/cgroups.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :prepare_cgroups_hash
    MockFunction.new(:prepare_cgroups_hash) do |function|
      allow(function).to receive(:call).and_return({})
    end
  end

  shared_examples 'catalog' do
    cgroups_hash = Noop.hiera_structure('cgroups', nil)
    if cgroups_hash
      it 'should declare cgroups class correctly' do
        should contain_class('cgroups').with(
          'cgroups_set'  => {},
        )
      end
    end
  end
  test_ubuntu_and_centos manifest
end
