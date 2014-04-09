require 'spec_helper'

describe 'nova::utilities' do

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it 'installes utilities' do
      should contain_package('unzip').with_ensure('present')
      should contain_package('screen').with_ensure('present')
      should contain_package('parted').with_ensure('present')
      should contain_package('curl').with_ensure('present')
      should contain_package('euca2ools').with_ensure('present')
      should contain_package('libguestfs-tools').with_ensure('present')
    end
  end
end
