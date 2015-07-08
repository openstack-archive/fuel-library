require 'spec_helper'

describe 'keystone::db::mysql' do

  let :pre_condition do
    [
      'include mysql::server',
      'include keystone::db::sync'
    ]
  end

  let :facts do
    { :osfamily => 'Debian' }
  end

  let :params do
    {
      'password'      => 'keystone_default_password',
    }
  end

  describe 'with only required params' do
    it { is_expected.to contain_openstacklib__db__mysql('keystone').with(
      'user'          => 'keystone',
      'password_hash' => '*B552157B14BCEDDCEAA06767A012F31BDAA9CE3D',
      'dbname'        => 'keystone',
      'host'          => '127.0.0.1',
      'charset'       => 'utf8',
      :collate        => 'utf8_general_ci',
    )}
  end

  describe "overriding allowed_hosts param to array" do
    let :params do
      {
        :password       => 'keystonepass',
        :allowed_hosts  => ['127.0.0.1','%']
      }
    end

  end
  describe "overriding allowed_hosts param to string" do
    let :params do
      {
        :password       => 'keystonepass2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

  end

  describe "overriding allowed_hosts param equals to host param " do
    let :params do
      {
        :password       => 'keystonepass2',
        :allowed_hosts  => '127.0.0.1'
      }
    end

  end

end
