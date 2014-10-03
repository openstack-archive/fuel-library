require 'spec_helper'

describe 'monit::service' do
  let(:facts) { { :osfamily => 'debian' } }
  it { should contain_service('monit') }

  let(:facts) { { :osfamily => 'redhat' } }
  it { should contain_service('monit') }
end
