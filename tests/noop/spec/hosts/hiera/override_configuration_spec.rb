# HIERA: neut_tun.ceph.murano.sahara.ceil-mongo
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-mongo
# HIERA: neut_vlan.murano.sahara.ceil-mongo
# HIERA: neut_vlan.murano.sahara.ceil-primary-mongo
# HIERA: neut_vlan.murano.sahara.ceil-cinder
# HIERA: neut_tun.ironic-ironic
# HIERA: neut_tun.ceph.murano.sahara.ceil-ceph-osd
# HIERA: neut_vlan.ceph-ceph-osd
# HIERA: neut_tun.ceph.murano.sahara.ceil-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ironic-primary-controller
# HIERA: neut_tun.l3ha-primary-controller
# HIERA: neut_vlan.ceph-primary-controller
# HIERA: neut_vlan.dvr-primary-controller
# HIERA: neut_vlan.murano.sahara.ceil-controller
# HIERA: neut_vlan.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-compute
# HIERA: neut_vlan.ceph-compute
# HIERA: neut_vlan.murano.sahara.ceil-compute
# R_N: neut_gre.generate_vms

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

