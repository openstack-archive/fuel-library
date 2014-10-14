require 'spec_helper'

describe 'monit::config' do
  describe 'when debian' do
    let(:facts) { { :osfamily => 'debian' } }
    it { should contain_file('/etc/monit/monitrc') }
  end

  describe 'when redhat' do
    let(:facts) { { :osfamily => 'redhat' } }
    it { should contain_file('/etc/monit.conf') }
  end
end
