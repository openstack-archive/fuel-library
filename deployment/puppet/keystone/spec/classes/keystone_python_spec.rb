require 'spec_helper'

describe 'keystone::python' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  it { should contain_package('python-keystone').with_ensure("present") }

  describe 'override ensure' do
    let(:params) { { :ensure => "latest" } }

    it { should contain_package('python-keystone').with_ensure("latest") }
  end

end
