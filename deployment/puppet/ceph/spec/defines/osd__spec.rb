require 'spec_helper'

describe 'ceph::osds::osd', :type => :define do
  let :facts do
    { :hostname => 'test.example' }
  end

  context 'Simple test' do
    let(:title) { '/dev/svv' }

    it { should contain_exec("ceph-deploy osd prepare test.example:/dev/svv").with(
      'command'   => 'ceph-deploy osd prepare test.example:/dev/svv',
      'returns'   => 0,
      'timeout'   => 0,
      'tries'     => 2,
      'try_sleep' => 1,
      'logoutput' => true,
      'unless'    => "ceph-disk list | fgrep -q -e '/dev/svv ceph data, active' -e '/dev/svv ceph data, prepared'",
      )
    }
    it { should contain_exec("ceph-deploy osd activate test.example:/dev/svv").with(
      'command'   => 'ceph-deploy osd activate test.example:/dev/svv',
      'try_sleep' => 10,
      'tries'     => 3,
      'logoutput' => true,
      'timeout'   => 0,
    )
    }
  end

  context 'Simple test with journal' do
    let(:title) { '/dev/sdd:/dev/journal' }
    it { should contain_exec("ceph-deploy osd prepare test.example:/dev/sdd:/dev/journal").with(
      'command'   => 'ceph-deploy osd prepare test.example:/dev/sdd:/dev/journal',
      'returns'   => 0,
      'timeout'   => 0,
      'tries'     => 2,
      'try_sleep' => 1,
      'logoutput' => true,
      'unless'    => "ceph-disk list | fgrep -q -e '/dev/sdd ceph data, active' -e '/dev/sdd ceph data, prepared'",
      )
    }
    it { should contain_exec("ceph-deploy osd activate test.example:/dev/sdd:/dev/journal").with(
      'command'   => 'ceph-deploy osd activate test.example:/dev/sdd:/dev/journal',
      'try_sleep' => 10,
      'tries'     => 3,
      'logoutput' => true,
      'timeout'   => 0,
      )
    }
  end

end

# vim: set ts=2 sw=2 et :
