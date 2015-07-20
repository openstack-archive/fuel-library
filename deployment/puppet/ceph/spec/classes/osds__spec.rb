require 'spec_helper'

describe 'ceph::osds', :type => :class do

  context 'Simple ceph::osds class test' do
    let (:params) {{ :devices => ['/dev/vdc', '/dev/vdd' ] }}

    it { should contain_exec('udevadm trigger') }
    it { should contain_exec('ceph-disk activate-all').that_requires('Exec[udevadm trigger]') }
    it { should contain_firewall('011 ceph-osd allow').that_requires('Exec[ceph-disk activate-all]') }
    it { should contain_ceph__osds__osd('/dev/vdc').that_requires('Firewall[011 ceph-osd allow]') }
    it { should contain_ceph__osds__osd('/dev/vdd').that_requires('Firewall[011 ceph-osd allow]') }
  end


  context 'Class ceph::osds without devices' do
    let (:params) {{ :devices => nil }}

    it { should contain_firewall('011 ceph-osd allow') }
    it { should_not contain_ceph__osds__osd }
  end

  context 'Class ceph::osds with devices and journals' do
    let (:params) {{ :devices => ['/dev/sdc1:/dev/sdc2', '/dev/sdd1:/dev/sdd2'] }}

    it { should contain_firewall('011 ceph-osd allow') }
    it { should contain_ceph__osds__osd('/dev/sdc1:/dev/sdc2') }
    it { should contain_ceph__osds__osd('/dev/sdd1:/dev/sdd2') }
  end

end

# vim: set ts=2 sw=2 et :
