require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-client.pp'

# HIERA: neut_vlan.ceph.compute-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  test_ubuntu_and_centos manifest
end

