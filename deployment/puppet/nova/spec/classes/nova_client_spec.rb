require 'spec_helper'

describe 'nova::client' do
  it { should contain_package('python-novaclient').with_ensure('present') }
  describe "with specified version" do
  	let :params do
      {:ensure => '2012.1-2'}
    end

    it { should contain_package('python-novaclient').with_ensure('2012.1-2') }
  end
end
