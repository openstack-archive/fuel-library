require 'spec_helper'

describe 'monit::package' do
  let(:facts) { { :osfamily => 'debian' } }
  it { should contain_package('monit') }

  let(:facts) { { :osfamily => 'redhat' } }
  it { should contain_package('monit') }
end
