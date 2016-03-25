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
manifest = 'ceph/enable_rados.pp'

describe manifest do
  shared_examples 'catalog' do
    it "should contain radowgw service" do

      if facts[:operatingsystem] == 'Ubuntu'
        should contain_service('radosgw').with(
          :enable   => 'false',
          :provider => 'debian'
        )

        should contain_service('radosgw-all').with(
          :ensure   => 'running',
          :enable   => 'true',
          :provider => 'upstart'
        )
      else
        should contain_service('ceph-radosgw').with(
          :ensure => 'running',
          :enable => 'true'
        )
      end
    end

    it "should create radosgw init override file on Ubuntu" do
        if facts[:operatingsystem] == 'Ubuntu'
          should contain_file("/etc/init/radosgw-all.override").with(
            :ensure  => 'present',
            :mode    => '0644',
            :owner   => 'root',
            :group   => 'root',
            :content => "start on runlevel [2345]\nstop on starting rc RUNLEVEL=[016]\n"

          )
        end
    end
  end

  test_ubuntu_and_centos manifest
end
