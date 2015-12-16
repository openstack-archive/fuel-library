# ROLE: primary-controller
# ROLE: controller
# ROLE: ceph-osd

require 'spec_helper'
require 'shared-examples'
manifest = 'ceph/updatedb.pp'

describe manifest do
  shared_examples 'catalog' do
    storage_hash = Noop.hiera_hash 'storage'

if (storage_hash['volumes_ceph'] or
    storage_hash['images_ceph'] or
    storage_hash['objects_ceph'])
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

