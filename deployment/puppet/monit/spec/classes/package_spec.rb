require 'spec_helper'

describe 'monit::package' do
  describe 'when debian' do
    let(:facts) { { :osfamily => 'debian' } }
    it { should contain_package('monit') }
  end

  describe 'when redhat' do
    let(:facts) { { :osfamily => 'redhat' } }
    it { should contain_package('monit') }
  end
end
