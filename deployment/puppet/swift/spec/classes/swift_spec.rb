require 'spec_helper'

describe 'swift' do

  let :params do
    {:swift_hash_suffix => 'string'}
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian'
    }
  end

  describe 'when no swift hash is specified' do
    let :params do
      {}
    end
    it 'should raise an exception' do
      expect { subject }.to raise_error(Puppet::Error)
    end
  end


  describe 'when using the default value for package_ensure' do
    let :file_defaults do
      {
        :owner   => 'swift',
        :group   => 'swift',
        :require => 'Package[swift]'
      }
    end
    it {should contain_user('swift')}
    it {should contain_file('/home/swift').with(
      {:ensure => 'directory', :mode => '0700'
      }.merge(file_defaults)
    )}
    it {should contain_file('/etc/swift').with(
      {:ensure => 'directory', :mode => '2770'
      }.merge(file_defaults)
    )}
    it {should contain_file('/var/run/swift').with(
      {:ensure => 'directory'}.merge(file_defaults)
    )}
    it {should contain_file('/var/lib/swift').with(
      {:ensure => 'directory'}.merge(file_defaults)
    )}
    it {should contain_file('/etc/swift/swift.conf').with(
      {:ensure  => 'present',
       :mode    => '0660',
      }.merge(file_defaults)
    )}
    it 'configures swift.conf' do
      should contain_swift_config(
        'swift-hash/swift_hash_path_suffix').with_value('string')
    end
    it {should contain_package('swift').with_ensure('present')}
  end

  describe 'when overriding package_ensure parameter' do
    it 'should effect ensure state of swift package' do
      params[:package_ensure] = '1.12.0-1'
      subject.should contain_package('swift').with_ensure(params[:package_ensure])
    end
  end

  describe 'when overriding client_package_ensure parameter' do
    it 'should effect ensure state of swift package' do
      params[:client_package_ensure] = '2.0.2-1'
      subject.should contain_package('swiftclient').with_ensure(params[:client_package_ensure])
    end
  end


end
