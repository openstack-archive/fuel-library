require 'spec_helper'

describe 'ceph::osds', :type => :class do

  context 'Simple ceph::osds class test' do
    let (:params) {{ :devices => ['foo', 'ba' ] }}

    it { should contain_firewall('011 ceph-osd allow') }
    it { should contain_ceph__osds__osd('foo') }
    it { should contain_ceph__osds__osd('ba') }
  end


  context 'Class ceph::osds class without devices' do
    let (:params) {{ :devices => nil }}

    it { should contain_firewall('011 ceph-osd allow') }
    it { should_not contain_ceph__osds__osd }
  end

end


