# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: controller
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder
# ROLE: ceph-osd
# R_N: neut_gre.generate_vms ubuntu
require 'spec_helper'
require 'shared-examples'
manifest = 'dns/dns-client.pp'

describe manifest do
  test_ubuntu_and_centos manifest
end

