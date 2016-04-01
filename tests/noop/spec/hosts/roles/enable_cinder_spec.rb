# RUN: neut_vlan.murano.sahara.ceil-cinder ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-compute ubuntu
# RUN: neut_vlan.ceph-compute ubuntu
# RUN: neut_vlan.murano.sahara.ceil-compute ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'roles/enable_cinder.pp'

describe manifest do
  shared_examples 'catalog' do

    it "should contain cinder-volume service" do
      case facts[:operatingsystem]
      when 'Ubuntu'
        service_name = 'cinder-volume'
      when 'CentOS'
        service_name = 'openstack-cinder-volume'
      else
        service_name = 'cinder-volume'
      end
      should contain_service(service_name)
    end
  end
  test_ubuntu_and_centos manifest
end
