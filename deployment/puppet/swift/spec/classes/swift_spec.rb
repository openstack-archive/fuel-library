require 'spec_helper'

describe 'swift' do

  let :params do
    {
      :swift_hash_suffix => 'string',
      :max_header_size   => '16384',
    }
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
      expect { catalogue }.to raise_error(Puppet::Error)
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
    it {is_expected.to contain_user('swift')}
    it {is_expected.to contain_file('/etc/swift').with(
      {:ensure => 'directory', :mode => '2770'
      }.merge(file_defaults)
    )}
    it {is_expected.to contain_file('/var/run/swift').with(
      {:ensure => 'directory'}.merge(file_defaults)
    )}
    it {is_expected.to contain_file('/var/lib/swift').with(
      {:ensure => 'directory'}.merge(file_defaults)
    )}
    it {is_expected.to contain_file('/etc/swift/backups').with(
      {:ensure => 'directory'}.merge(file_defaults)
    )}
    it {is_expected.to contain_file('/etc/swift/swift.conf').with(
      { :ensure => 'file',
        :mode   => '0660'
      }.merge(file_defaults)
    )}
    it 'configures swift.conf' do
      is_expected.to contain_swift_config(
        'swift-hash/swift_hash_path_suffix').with_value('string')
    end
    it 'configures swift.conf' do
      is_expected.to contain_swift_config(
        'swift-constraints/max_header_size').with_value('16384')
    end
    it { is_expected.to contain_package('swift').with_ensure('present') }
  end

  describe 'when overriding package_ensure parameter' do
    it 'should effect ensure state of swift package' do
      params[:package_ensure] = '1.12.0-1'
      is_expected.to contain_package('swift').with_ensure(params[:package_ensure])
    end
  end

  describe 'when overriding client_package_ensure parameter' do
    it 'should effect ensure state of swift package' do
      params[:client_package_ensure] = '2.0.2-1'
      is_expected.to contain_package('swiftclient').with_ensure(params[:client_package_ensure])
    end
  end

end
