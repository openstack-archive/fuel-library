require 'spec_helper'

describe 'keystone::python' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  it { should contain_package('python-keystone') }

end
