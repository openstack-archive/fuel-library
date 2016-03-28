# RUN: neut_gre.generate_vms ubuntu
# RUN: neut_vlan.ceph.ceil-compute.overridden_ssl ubuntu
# RUN: neut_vlan.ceph.compute-ephemeral-ceph ubuntu
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.cinder-block-device.compute ubuntu
# RUN: neut_vlan.compute.nossl ubuntu
# RUN: neut_vlan.compute.ssl ubuntu
# RUN: neut_vlan.compute.ssl.overridden ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-ceph-osd ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-compute ubuntu
# RUN: neut_vlan_l3ha.ceph.ceil-primary-mongo ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-cinder ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-compute ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-client.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

