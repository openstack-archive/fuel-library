# RUN: neut_tun.ceph.murano.sahara.ceil-mongo ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-mongo ubuntu
# RUN: neut_vlan.murano.sahara.ceil-cinder ubuntu
# RUN: neut_tun.ironic-ironic ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-ceph-osd ubuntu
# RUN: neut_vlan.ceph-ceph-osd ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-compute ubuntu
# RUN: neut_vlan.ceph-compute ubuntu
# RUN: neut_vlan.murano.sahara.ceil-compute ubuntu
# R_N: neut_gre.generate_vms ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'hiera/hiera.pp'

describe manifest do
  shared_examples 'catalog' do
    it 'should setup hiera' do
      should contain_file('hiera_data_dir').with(
        'ensure' => 'directory',
        'path'   => '/etc/hiera'
      )
      should contain_file('hiera_config').with(
        'ensure' => 'present',
        'path'   => '/etc/hiera.yaml'
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

