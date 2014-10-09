require 'spec_helper'

describe 'swift::client' do
  it { should contain_package('swiftclient').with(
    :ensure => 'present',
    :name => 'python-swiftclient'
  )}
  let :facts do
    {:osfamily => 'Debian'}
  end
  context 'with params' do
    let :params do
      {:ensure => 'latest'}
    end
    it { should contain_package('swiftclient').with(
      :ensure => 'latest',
      :name   => 'python-swiftclient'
    )}
  end
end
