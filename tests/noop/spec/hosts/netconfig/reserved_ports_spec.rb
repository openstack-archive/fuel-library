require 'spec_helper'
require 'shared-examples'
manifest = 'netconfig/reserved_ports.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do

    it { should contain_class('openstack::reserved_ports') }
  end

  test_ubuntu_and_centos manifest
end

