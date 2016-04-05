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
manifest = 'cluster/cluster.pp'

describe manifest do
  shared_examples 'catalog' do

    cluster_recheck_interval = Noop.hiera('cluster_recheck_interval', '190s')

    it { should contain_class('cluster').with({
      'cluster_recheck_interval' => cluster_recheck_interval,
      })
    }
    it { should contain_pcmk_nodes('pacemaker') }
    it { should contain_service('corosync').that_comes_before('Pcmk_nodes[pacemaker]') }
    it { should contain_service('corosync').with({
         'subscribe' => 'File[/etc/corosync/service.d]',
         'require'   => 'File[/etc/corosync/corosync.conf]',
         })
    }

    it do
      if (facts[:operatingsystem] == 'Ubuntu')
        should contain_file('/etc/corosync/uidgid.d/pacemaker').that_requires('File[/etc/corosync/corosync.conf]')
      elsif
        should_not contain_file('/etc/corosync/uidgid.d/pacemaker')
      end
    end

    it do
      if (facts[:operatingsystem] == 'Ubuntu')
        should contain_file('/etc/corosync/uidgid.d/pacemaker').that_comes_before('Service[corosync]')
      end
    end

  end
  test_ubuntu_and_centos manifest
end

