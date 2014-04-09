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

    it { should contain_nova_config('DEFAULT/novncproxy_host').with(:value => '0.0.0.0') }
    it { should contain_nova_config('DEFAULT/novncproxy_port').with(:value => '6080') }

    it { should contain_package('nova-vncproxy').with(
      :name   => 'nova-novncproxy',
      :ensure => 'present'
    ) }
    it { should contain_service('nova-vncproxy').with(
      :name      => 'nova-novncproxy',
      :hasstatus => true,
      :ensure    => 'running'
    )}

    describe 'with manage_service as false' do
      let :params do
        { :enabled        => true,
          :manage_service => false
        }
      end
      it { should contain_service('nova-vncproxy').without_ensure }
    end

    describe 'with package version' do
      let :params do
        {:ensure_package => '2012.1-2'}
      end
      it { should contain_package('nova-vncproxy').with(
        'ensure' => '2012.1-2'
      )}
    end

  end

  describe 'on debian OS' do
      let :facts do
        { :osfamily => 'Debian', :operatingsystem => 'Debian' }
      end
      it { should contain_package('nova-vncproxy').with(
        :name   => "nova-consoleproxy",
        :ensure => 'present'
      )}
      it { should contain_service('nova-vncproxy').with(
        :name      => 'nova-novncproxy',
        :hasstatus => true,
        :ensure    => 'running'
      )}
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
