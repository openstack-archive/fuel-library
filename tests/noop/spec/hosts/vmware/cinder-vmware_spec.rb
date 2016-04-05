# HIERA: neut_tun.ceph.murano.sahara.ceil-compute
# HIERA: neut_vlan.ceph-compute
# HIERA: neut_vlan.murano.sahara.ceil-compute

require 'spec_helper'
require 'shared-examples'
manifest = 'vmware/cinder-vmware.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

