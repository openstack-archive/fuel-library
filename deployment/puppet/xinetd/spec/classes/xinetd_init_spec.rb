require 'spec_helper'

describe 'xinetd' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  it {
    should contain_package('xinetd')
    should contain_file('/etc/xinetd.conf')
    should contain_service('xinetd')
  }
end
