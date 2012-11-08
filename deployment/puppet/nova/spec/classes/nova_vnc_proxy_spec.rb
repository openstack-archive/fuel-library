require 'spec_helper'

describe 'nova::vncproxy' do

  let :pre_condition do
    'include nova'
  end

  let :params do
    {:enabled => true}
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it { should contain_package('python-numpy').with(
      :ensure => 'present',
      :name   => 'python-numpy'
    )}

    it { should contain_nova_config('novncproxy_host').with(:value => '0.0.0.0') }
    it { should contain_nova_config('novncproxy_port').with(:value => '6080') }

    it { should contain_package('nova-vncproxy').with(
      :name   => ["novnc", "nova-novncproxy"],
      :ensure => 'present'
    ) }
    it { should contain_service('nova-vncproxy').with(
      :name   => 'nova-novncproxy',
      :ensure => 'running'
    )}

    describe 'with package version' do
      let :params do
        {:ensure_package => '2012.1-2'}
      end
      it { should contain_package('nova-vncproxy').with(
        'ensure' => '2012.1-2'
      )}
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
