require 'spec_helper'

describe 'xinetd' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  describe 'with defaults' do
    it {
      should contain_package('xinetd')
      should contain_file('/etc/xinetd.conf')
      should contain_file('/etc/xinetd.d').with_ensure('directory')
      should contain_file('/etc/xinetd.d').with_recurse(false)
      should contain_file('/etc/xinetd.d').with_purge(false)
      should contain_service('xinetd')
    }
  end

  describe 'with managed confdir' do
    let :params do
      { :purge_confdir => true }
    end

    it {
      should contain_package('xinetd')
      should contain_file('/etc/xinetd.conf')
      should contain_file('/etc/xinetd.d').with_ensure('directory')
      should contain_file('/etc/xinetd.d').with_recurse(true)
      should contain_file('/etc/xinetd.d').with_purge(true)
      should contain_service('xinetd')
    }
  end
end
