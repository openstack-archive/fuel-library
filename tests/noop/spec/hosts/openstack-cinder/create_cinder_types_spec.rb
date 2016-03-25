# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-controller.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute.yaml ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-controller.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute.yaml ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd.yaml ubuntu
# RUN: neut_vlan.ironic.controller.yaml ubuntu
# RUN: neut_vlan.ironic.conductor.yaml ubuntu
# RUN: neut_vlan.compute.ssl.yaml ubuntu
# RUN: neut_vlan.compute.ssl.overridden.yaml ubuntu
# RUN: neut_vlan.compute.nossl.yaml ubuntu
# RUN: neut_vlan.cinder-block-device.compute.yaml ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-primary-controller.overridden_ssl.yaml ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl.yaml ubuntu
# RUN: neut_gre.generate_vms.yaml ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-cinder/create_cinder_types.pp'

describe manifest do
  shared_examples 'catalog' do

    volume_backend_names      = Noop.hiera_structure 'storage/volume_backend_names'
    available_backends        = volume_backend_names.select { |key, value| value }
    available_backend_names   = available_backends.keys
    unavailable_backends      = volume_backend_names.select { |key,value| ! value }
    unavailable_backend_names = unavailable_backends.keys

    available_backend_names.each do |backend_name|
      it "should create cinder type #{backend_name}" do
         should contain_osnailyfacter__openstack__manage_cinder_types(backend_name).with(
           :ensure               => 'present',
           :volume_backend_names => available_backends,
         )
      end
    end

    unavailable_backend_names.each do |backend_name|
      it "should remove cinder type #{backend_name}" do
         should contain_osnailyfacter__openstack__manage_cinder_types(backend_name).with(
           :ensure => 'absent',
         )
      end
    end

  end

  test_ubuntu_and_centos manifest
end
