require 'spec_helper'

describe 'nova::vncproxy' do

  let :pre_condition do
    'include nova'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it { should contain_package('python-numpy').with(
      :ensure => 'present',
      :name   => 'python-numpy'
    )}

    it { should contain_nova_config('novncproxy_base_url').with(
      :value => 'http://127.0.0.1:6080/vnc_auto.html'
    )}

    it { should contain_package('noVNC').with_ensure('purged') }
    it { should contain_class('git') }
    it { should contain_vcsrepo('/var/lib/nova/noVNC').with(
      :ensure   => 'latest',
      :provider => 'git',
      :source   => 'https://github.com/cloudbuilders/noVNC.git',
      :revision => 'HEAD',
      :require  => 'Package[nova-api]',
      :before   => 'Nova::Generic_service[vncproxy]'
    ) }
    #describe 'when deployed on the API server' do
    #  let :pre_condition do
    #    'include nova::api'
    #  end
    #  it { should contain_package('nova-vncproxy').with(
    #    'ensure' => 'present',
    #    'before' => 'Exec[initial-db-sync]'
    #  )}
    #end

    describe 'on Debian OS' do
      let :facts do
        { :osfamily => 'Debian', :operatingsystem => 'Debian' }
      end

      it { should_not contain_class('git') }
      it { should_not contain_vcsrepo('/var/lib/nova/noVNC') }
    end
  end

  describe 'on Redhatish platforms' do

    let :facts do
      { :osfamily => 'Redhat' }
    end

    it { should contain_package('python-numpy').with(
      :name   => 'numpy',
      :ensure => 'present'
    )}

  end

end
