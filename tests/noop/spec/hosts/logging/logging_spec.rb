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
manifest = 'logging/logging.pp'

describe manifest do
  shared_examples 'catalog' do
    it {
      if facts[:operatingsystem] == 'Ubuntu'
        should contain_file('/var/log').with(
          'owner' => 'root',
          'group' => 'syslog',
          'mode'  => '0775'
        )
      else
        should_not contain_file('/var/log')
      end
    }
    if Noop.hiera('role') == 'ironic'
      it {
        should contain_file('/etc/rsyslog.d/70-ironic.conf').with(
          'owner' => 'root',
          'group' => 'syslog',
          'mode'  => '0640',
        )
      }
    end

    it {
      should contain_class('cluster::haproxy::rsyslog')
    }
  end
  test_ubuntu_and_centos manifest
end

