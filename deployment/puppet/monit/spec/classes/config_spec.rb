require 'spec_helper'

describe 'monit::config' do
  let(:facts) { { :osfamily => 'debian' } }
  it { should contain_file('/etc/monit/monitrc') }

  let(:facts) { { :osfamily => 'redhat' } }
  it { should contain_file('/etc/monit.conf') }
end
