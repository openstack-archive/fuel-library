require 'spec_helper'
require 'shared-examples'
manifest = 'astute/enable_compute.pp'

# HIERA: neut_vlan.ceph.compute-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do

    it "should contain nova-compute service" do
      case facts[:operatingsystem]
      when 'Ubuntu'
        service_name = 'nova-compute'
      when 'CentOS'
        service_name = 'openstack-nova-compute'
      else
        service_name = 'nova-compute'
      end

      should contain_service(service_name)
    end

  end
  test_ubuntu_and_centos manifest
end
