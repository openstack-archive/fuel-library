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
manifest = 'vmware/compute-vmware.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should have cache_prefix option set to $host' do
      should contain_file('/etc/nova/nova-compute.conf').with_content(
        %r{\n\s*cache_prefix=\$host\n}
      )
    end

    network_manager = Noop.hiera_structure('novanetwork_parameters/network_manager')

    if network_manager == 'VlanManager'
      it 'should have vlan_interface option set to vmnic0' do
        should contain_file('/etc/nova/nova-compute.conf').with_content(
          %r{\n\s*vlan_interface=vmnic0\n}
        )
      end
    end

    ceilometer_enabled = Noop.hiera_structure('ceilometer/enabled')

    if ceilometer_enabled == 'true'
      it 'should have /etc/ceilometer/ceilometer.conf' do
        should contain_file('/etc/ceilometer/ceilometer.conf').with_content(
          %r{\n\s*hypervisor_inspector=vsphere\n}
        )
      end
    end

  end # end of shared_examples

  test_ubuntu_and_centos manifest
 end

