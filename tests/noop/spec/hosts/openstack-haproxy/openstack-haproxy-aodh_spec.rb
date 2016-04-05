# HIERA: neut_tun.ceph.murano.sahara.ceil-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ironic-primary-controller
# HIERA: neut_tun.l3ha-primary-controller
# HIERA: neut_vlan.ceph-primary-controller
# HIERA: neut_vlan.dvr-primary-controller
# HIERA: neut_vlan.murano.sahara.ceil-controller
# HIERA: neut_vlan.murano.sahara.ceil-primary-controller
# SKIP_HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl FIXME
# SKIP_HIERA: neut_vlan_l3ha.ceph.ceil-controller ubuntu FIXME
# SKIP_HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller ubuntu FIXME

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-haproxy/openstack-haproxy-aodh.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end
