# RUN: neut_tun.ceph.murano.sahara.ceil-controller ubuntu
# RUN: neut_tun.ceph.murano.sahara.ceil-primary-controller ubuntu
# RUN: neut_tun.ironic-primary-controller ubuntu
# RUN: neut_tun.l3ha-primary-controller ubuntu
# RUN: neut_vlan.ceph-primary-controller ubuntu
# RUN: neut_vlan.dvr-primary-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-controller ubuntu
# RUN: neut_vlan.murano.sahara.ceil-primary-controller ubuntu

require 'spec_helper'
require 'shared-examples'
manifest = 'umm/umm.pp'

describe manifest do
  shared_examples 'catalog' do
    role = Noop.hiera 'role'
    it 'ensures fuel-umm installed and /etc/umm.conf is present' do
      if role == 'primary-controller' or role == 'controller'
        should contain_package('fuel-umm')
        should contain_file('umm_config').with(
          'ensure' => 'present',
          'path'   => '/etc/umm.conf',
        )
      end
    end
  end # end of shared_examples
  test_ubuntu_and_centos manifest
end

