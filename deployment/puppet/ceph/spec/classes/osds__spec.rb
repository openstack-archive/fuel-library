require 'spec_helper'

describe 'ceph::osds', :type => :class do

  context 'Simple ceph::osds class test' do
    let (:params) {{ :devices => ['/dev/vdc', '/dev/vdd' ],
                     :use_prepared_devices => false }}

    it { should contain_firewall('011 ceph-osd allow') }
    it { should contain_ceph__osds__osd('/dev/vdc') }
    it { should contain_ceph__osds__osd('/dev/vdd') }
  end


  context 'Class ceph::osds without devices' do
    let (:params) {{ :devices => nil,
                     :use_prepared_devices => false }}

    it { should contain_firewall('011 ceph-osd allow') }
    it { should_not contain_ceph__osds__osd }
  end

  context 'Class ceph::osds with devices and journals' do
    let (:params) {{ :devices => ['/dev/sdc1:/dev/sdc2', '/dev/sdd1:/dev/sdd2'],
                     :use_prepared_devices => false }}

    it { should contain_firewall('011 ceph-osd allow') }
    it { should contain_ceph__osds__osd('/dev/sdc1:/dev/sdc2') }
    it { should contain_ceph__osds__osd('/dev/sdd1:/dev/sdd2') }
  end

  context 'Class ceph::osds with prepared devices' do
    let (:params) {{ :devices => ['/dev/vdc', '/dev/vdd' ],
                     :use_prepared_devices => true }}

    it { should contain_firewall('011 ceph-osd allow') }
    it { should contain_ceph__osds__osd('/dev/vdc') }
    it { should contain_ceph__osds__osd('/dev/vdd') }
  end

end

# vim: set ts=2 sw=2 et :
