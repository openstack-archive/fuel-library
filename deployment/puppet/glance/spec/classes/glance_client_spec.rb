require 'spec_helper'

describe 'glance::client' do

  shared_examples 'glance client' do
    it { should contain_class('glance::params') }
    it { should contain_package('python-glanceclient').with(
        :name   => 'python-glanceclient',
        :ensure => 'present'
      )
    }
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    include_examples 'glance client'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    include_examples 'glance client'
  end
end
