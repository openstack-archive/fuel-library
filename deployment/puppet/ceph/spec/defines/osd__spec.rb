require 'spec_helper'

describe 'ceph::osds::osd', :type => :define do
  let(:title) { '/dev/svv' }
  let :facts do
    { :hostname => 'test.example', }
  end

  context 'simple test' do
    it { should contain_exec("ceph-deploy osd prepare test.example:/dev/svv")  }
  end
end
