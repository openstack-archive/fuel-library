require 'spec_helper'

describe 'nova::client' do

  context 'with default parameters' do
    it {
      is_expected.to contain_package('python-novaclient').with(
        :ensure => 'present',
        :tag    => ['openstack']
      )
    }
  end

  context 'with ensure parameter provided' do
    let :params do
      { :ensure => '2012.1-2' }
    end
    it { is_expected.to contain_package('python-novaclient').with_ensure('2012.1-2') }
  end
end
