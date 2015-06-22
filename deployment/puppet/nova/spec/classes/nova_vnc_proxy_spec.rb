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

    it { is_expected.to contain_package('python-numpy').with(
      :ensure => 'present',
      :name   => 'python-numpy'
    )}

    it { is_expected.to contain_nova_config('DEFAULT/novncproxy_host').with(:value => '0.0.0.0') }
    it { is_expected.to contain_nova_config('DEFAULT/novncproxy_port').with(:value => '6080') }
    it { is_expected.to contain_nova_config('DEFAULT/novncproxy_base_url').with(:value => 'http://0.0.0.0:6080/vnc_auto.html') }

    it { is_expected.to contain_package('nova-vncproxy').with(
      :name   => 'nova-novncproxy',
      :ensure => 'present'
    ) }
    it { is_expected.to contain_service('nova-vncproxy').with(
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
      it { is_expected.to contain_service('nova-vncproxy').without_ensure }
    end

    describe 'with package version' do
      let :params do
        {:ensure_package => '2012.1-2'}
      end
      it { is_expected.to contain_package('nova-vncproxy').with(
        'ensure' => '2012.1-2'
      )}
    end

  end

  describe 'on debian OS' do
      let :facts do
        { :osfamily => 'Debian', :operatingsystem => 'Debian' }
      end
      it { is_expected.to contain_package('nova-vncproxy').with(
        :name   => "nova-consoleproxy",
        :ensure => 'present'
      )}
      it { is_expected.to contain_service('nova-vncproxy').with(
        :name      => 'nova-novncproxy',
        :hasstatus => true,
        :ensure    => 'running'
      )}
  end


  describe 'on Redhatish platforms' do

    let :facts do
      { :osfamily => 'Redhat' }
    end

    it { is_expected.to contain_package('python-numpy').with(
      :name   => 'numpy',
      :ensure => 'present'
    )}

    it { is_expected.to compile.with_all_deps }

  end

end
