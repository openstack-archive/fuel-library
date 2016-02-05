require 'spec_helper'
require 'shared-examples'
manifest = 'dns/dns-client.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  test_ubuntu_and_centos manifest
end

