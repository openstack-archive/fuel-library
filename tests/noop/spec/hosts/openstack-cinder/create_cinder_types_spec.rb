# HIERA: neut_tun.ceph.murano.sahara.ceil-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ironic-primary-controller
# HIERA: neut_tun.l3ha-primary-controller
# HIERA: neut_vlan.ceph-primary-controller
# HIERA: neut_vlan.dvr-primary-controller
# HIERA: neut_vlan.murano.sahara.ceil-controller
# HIERA: neut_vlan.murano.sahara.ceil-primary-controller

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
