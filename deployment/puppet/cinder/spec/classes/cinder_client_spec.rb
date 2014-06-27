require 'spec_helper'

describe 'cinder::client' do
  it { should contain_package('python-cinderclient').with_ensure('present') }
  let :facts do
    {:osfamily => 'Debian'}
  end
  context 'with params' do
    let :params do
      {:package_ensure => 'latest'}
    end
    it { should contain_package('python-cinderclient').with_ensure('latest') }
  end
end
