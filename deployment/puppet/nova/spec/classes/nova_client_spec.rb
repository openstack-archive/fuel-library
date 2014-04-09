require 'spec_helper'

describe 'nova::client' do

  context 'with default parameters' do
    it { should contain_package('python-novaclient').with_ensure('present') }
  end

  context 'with ensure parameter provided' do
    let :params do
      { :ensure => '2012.1-2' }
    end
    it { should contain_package('python-novaclient').with_ensure('2012.1-2') }
  end
end
