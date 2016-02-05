require 'spec_helper'
require 'shared-examples'
manifest = 'ssl/ssl_add_trust_chain.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

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

