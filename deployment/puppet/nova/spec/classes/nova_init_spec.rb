require 'spec_helper'

describe 'nova' do
  let :facts do
    { :osfamily => 'Debian' }
  end 

  it do
    should contain_group('nova').with(
      'ensure'  => 'present',
      'system'  => 'true',
      'require' => 'Package[nova-common]'
    )
  end

  it do
    should contain_user('nova').with(
      'ensure'  => 'present',
      'gid'     => 'nova',
      'system'  => 'true',
      'require' => 'Package[nova-common]'
    )
  end
end
