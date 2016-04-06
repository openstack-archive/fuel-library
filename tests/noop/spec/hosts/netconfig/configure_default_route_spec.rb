# ROLE: primary-mongo
# ROLE: mongo
# ROLE: compute-vmware
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder
# ROLE: ceph-osd
# R_N: neut_gre.generate_vms ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/configure_default_route.pp'

describe manifest do
  shared_examples 'catalog' do

    use_neutron      = Noop.hiera 'use_neutron'

    it { should contain_class('l23network').with('use_ovs' => use_neutron) }

  end

  test_ubuntu_and_centos manifest
end

