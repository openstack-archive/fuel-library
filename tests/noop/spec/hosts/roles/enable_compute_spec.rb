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
manifest = 'roles/enable_compute.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should contain nova-compute service' do
      service_name = case facts[:operatingsystem]
      when 'Ubuntu'
        'nova-compute'
      when 'CentOS'
        'openstack-nova-compute'
      else
        'nova-compute'
      end

      is_expected.to contain_service('nova-compute').with(
        :ensure     => 'running',
        :name       => service_name,
        :enable     => true,
        :hasstatus  => true,
        :hasrestart => true,
      )
    end

    if Noop.hiera('use_ovs') && Noop.hiera('role') == 'compute'
      neutron_integration_bridge = 'br-int'
      bridge_exists_check = "ovs-vsctl br-exists #{neutron_integration_bridge}"

      it 'should contain wait-for-int-br exec' do
        is_expected.to contain_exec('wait-for-int-br').with(
            :command   => bridge_exists_check,
            :unless    => bridge_exists_check,
            :try_sleep => 6,
            :tries     => 10,
          ).that_comes_before('Service[nova-compute]')
      end
    end

  end

  test_ubuntu_and_centos manifest
end
