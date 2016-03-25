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
manifest = 'cluster/health.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:facts) {
      Noop.ubuntu_facts.merge({
        :mounts => ['/', '/boot', '/var/log', '/var/lib/glance', '/var/lib/mysql', '/var/lib/horizon']
      })
    }

    let(:disks) do
      Noop.hiera 'corosync_disk_monitor', ['/', '/var/log', '/var/lib/glance', '/var/lib/mysql']
    end

    let(:min_disk_free) do
      Noop.hiera 'corosync_min_disk_space', '512M'
    end

    let(:disk_unit) do
      Noop.hiera 'corosync_disk_unit', 'M'
    end

    let(:monitor_interval) do
      Noop.hiera 'corosync_monitor_interval', '15s'
    end

    it {
      should contain_class('cluster::sysinfo').with(
        :disks              => disks,
        :min_disk_free      => min_disk_free,
        :disk_unit          => disk_unit,
        :monitor_interval   => monitor_interval
      )
    }

  end
  test_ubuntu_and_centos manifest
end

