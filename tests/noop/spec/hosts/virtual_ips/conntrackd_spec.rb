require 'spec_helper'
require 'shared-examples'
manifest = 'virtual_ips/conntrackd.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  test_ubuntu_and_centos manifest
end

