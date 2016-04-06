# ROLE: virt
# ROLE: primary-mongo
# ROLE: primary-controller
# ROLE: mongo
# ROLE: ironic
# ROLE: controller
# ROLE: compute-vmware
# ROLE: compute
# ROLE: cinder-vmware
# ROLE: cinder-block-device
# ROLE: cinder
# ROLE: ceph-osd
# ROLE: base-os

require 'spec_helper'
require 'shared-examples'
manifest = 'hiera/override_configuration.pp'

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

