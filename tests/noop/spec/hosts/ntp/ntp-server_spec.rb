# HIERA: neut_tun.ceph.murano.sahara.ceil-controller
# HIERA: neut_tun.ceph.murano.sahara.ceil-primary-controller
# HIERA: neut_tun.ironic-primary-controller
# HIERA: neut_tun.l3ha-primary-controller
# HIERA: neut_vlan.ceph-primary-controller
# HIERA: neut_vlan.dvr-primary-controller
# HIERA: neut_vlan.murano.sahara.ceil-controller
# HIERA: neut_vlan.murano.sahara.ceil-primary-controller

require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-server.pp'

describe manifest do
  shared_examples 'catalog' do

    it 'should disable monitor' do
      should contain_class('ntp').with('disable_monitor' => 'true')
    end

    it 'should pass restrictions explicitly' do
      should contain_class('ntp').with(
        'restrict' => [
            '-4 default kod nomodify notrap nopeer noquery',
            '-6 default kod nomodify notrap nopeer noquery',
            '127.0.0.1',
            '::1',
      ])
    end
  end
  test_ubuntu_and_centos manifest
end
