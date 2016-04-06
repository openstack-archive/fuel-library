# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: controller
# ROLE: compute-vmware
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder
# ROLE: ceph-osd

require 'spec_helper'
require 'shared-examples'
manifest = 'ssl/ssl_add_trust_chain.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should add certificates to trust chain' do
      should contain_exec('add_trust').with(
        'command' => 'update-ca-certificates',
      )
    end
  end
  test_ubuntu_and_centos manifest
end

