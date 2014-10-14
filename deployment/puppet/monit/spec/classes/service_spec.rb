require 'spec_helper'

describe 'monit::service' do
  describe 'when debian' do
    let(:facts) { { :osfamily => 'debian' } }
    it { should contain_service('monit') }
  end

  describe 'when redhat' do
    let(:facts) { { :osfamily => 'redhat' } }
    it { should contain_service('monit') }
  end
end
