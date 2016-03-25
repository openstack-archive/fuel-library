# SKIP_HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl FIXME
# RUN: neut_vlan.ceph.controller-ephemeral-ceph ubuntu
# RUN: neut_vlan.ironic.controller ubuntu
# SKIP_HIERA: neut_vlan_l3ha.ceph.ceil-controller ubuntu FIXME
# SKIP_HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu FIXME
# RUN: neut_vxlan_dvr.murano.sahara-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller ubuntu
# RUN: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-aodh.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end
