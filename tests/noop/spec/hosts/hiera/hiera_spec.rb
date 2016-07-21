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
manifest = 'hiera/hiera.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should setup hiera' do
      should contain_file('hiera_data_dir').with(
        'ensure' => 'directory',
        'path'   => '/etc/hiera',
        'mode'   => '0750',
      )
      should contain_file('hiera_config').with(
        'ensure' => 'present',
        'path'   => '/etc/hiera.yaml',
        'mode'   => '0640',
      )

      # ensure deeper merge_behavior is being set
      should contain_hiera_config('/etc/hiera.yaml').with(
        'merge_behavior' => 'deeper',
      )

      # ensure hiera_config is taking plugin overrides from the astute.yaml
      should contain_hiera_config('/etc/hiera.yaml').with(
        'ensure' => 'present',
        'metadata_yaml_file' => '/etc/astute.yaml',
        'override_dir' => 'plugins',
        'data_dir' => '/etc/hiera',
      )

      # check symlinks
      should contain_file('hiera_data_astute').with(
        'ensure' => 'symlink',
        'path'   => '/etc/hiera/astute.yaml',
        'target' => '/etc/astute.yaml'
      )
      should contain_file('hiera_puppet_config').with(
        'ensure' => 'symlink',
        'path'   => '/etc/puppet/hiera.yaml',
        'target' => '/etc/hiera.yaml'
      )
    end
  end

  test_ubuntu_and_centos manifest
end

