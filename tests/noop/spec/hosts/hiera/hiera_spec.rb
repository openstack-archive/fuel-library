# HIERA: neut_gre.generate_vms
# HIERA: neut_vlan.ceph.ceil-compute.overridden_ssl
# HIERA: neut_vlan.ceph.ceil-primary-controller.overridden_ssl
# HIERA: neut_vlan.ceph.compute-ephemeral-ceph
# HIERA: neut_vlan.ceph.controller-ephemeral-ceph
# HIERA: neut_vlan.cinder-block-device.compute
# HIERA: neut_vlan.compute.nossl
# HIERA: neut_vlan.compute.ssl
# HIERA: neut_vlan.compute.ssl.overridden
# HIERA: neut_vlan.ironic.conductor
# HIERA: neut_vlan.ironic.controller
# HIERA: neut_vlan_l3ha.ceph.ceil-ceph-osd
# HIERA: neut_vlan_l3ha.ceph.ceil-compute
# HIERA: neut_vlan_l3ha.ceph.ceil-controller
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-controller
# HIERA: neut_vlan_l3ha.ceph.ceil-primary-mongo
# HIERA: neut_vxlan_dvr.murano.sahara-cinder
# HIERA: neut_vxlan_dvr.murano.sahara-compute
# HIERA: neut_vxlan_dvr.murano.sahara-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller
# HIERA: neut_vxlan_dvr.murano.sahara-primary-controller.overridden_ssl

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

