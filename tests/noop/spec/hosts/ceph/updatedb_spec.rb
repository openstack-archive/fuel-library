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

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/updatedb.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera_hash 'storage'

    if (storage_hash['images_ceph'] or storage_hash['objects_ceph'] or storage_hash['objects_ceph'])
      it { should contain_exec('Ensure /var/lib/ceph in the updatedb PRUNEPATH').with(
        :path    => [ '/usr/bin', '/bin' ],
        :command => "sed -i -Ee 's|(PRUNEPATHS *= *\"[^\"]*)|\\1 /var/lib/ceph|' /etc/updatedb.conf",
        :unless  => "test ! -f /etc/updatedb.conf || grep 'PRUNEPATHS *= *.*/var/lib/ceph.*' /etc/updatedb.conf",
      )
      }
    else
      it { should_not contain_exec('Ensure /var/lib/ceph in the updatedb PRUNEPATH') }
    end
  end

  test_ubuntu_and_centos manifest
end

