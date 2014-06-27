require 'spec_helper'

describe 'neutron::db::mysql::host_access' do

  let :pre_condition do
    'include mysql'
  end

  let :title do
    '127.0.0.1'
  end

  let :params do
    { :user     => 'neutron',
      :password => 'passw0rd',
      :database => 'neutron' }
  end

  let :facts do
    { :osfamily => 'Debian' }
  end

  it { should contain_database_user('neutron@127.0.0.1') }
  it { should contain_database_grant('neutron@127.0.0.1/neutron') }
end
