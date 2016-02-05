require 'spec_helper'
require 'shared-examples'
manifest = 'hiera/override_configuration.pp'

# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# FACTS: ubuntu

describe manifest do
  shared_examples 'catalog' do
    it 'should setup hiera override configuration' do
      ['/etc/hiera/override', '/etc/hiera/override/configuration'].each do |f|
        should contain_file(f).with(
          'ensure' => 'directory',
          'path'   => f
        )
      end
    end
  end

  test_ubuntu_and_centos manifest
end

