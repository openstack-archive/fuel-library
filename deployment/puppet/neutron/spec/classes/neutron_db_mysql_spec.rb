require 'spec_helper'

describe 'neutron::db::mysql' do

  let :pre_condition do
    'include mysql::server'
  end

  let :params do
    { :password => 'passw0rd',
      :mysql_module => '0.9'
    }
  end
  let :facts do
      { :osfamily => 'Debian' }
  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it { should contain_class('neutron::db::mysql') }
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it { should contain_class('neutron::db::mysql') }
  end

  describe "overriding allowed_hosts param to array" do
    let :params do
      {
        :password       => 'neutronpass',
        :allowed_hosts  => ['127.0.0.1','%']
      }
    end

    it {should_not contain_neutron__db__mysql__host_access("127.0.0.1").with(
      :user     => 'neutron',
      :password => 'neutronpass',
      :database => 'neutron'
    )}
    it {should contain_neutron__db__mysql__host_access("%").with(
      :user     => 'neutron',
      :password => 'neutronpass',
      :database => 'neutron'
    )}
  end

  describe "overriding allowed_hosts param to string" do
    let :params do
      {
        :password       => 'neutronpass2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

    it {should contain_neutron__db__mysql__host_access("192.168.1.1").with(
      :user     => 'neutron',
      :password => 'neutronpass2',
      :database => 'neutron'
    )}
  end

  describe "overriding allowed_hosts param equals to host param " do
    let :params do
      {
        :password       => 'neutronpass2',
        :allowed_hosts  => '127.0.0.1'
      }
    end

    it {should_not contain_neutron__db__mysql__host_access("127.0.0.1").with(
      :user     => 'neutron',
      :password => 'neutronpass2',
      :database => 'neutron'
    )}
  end
end

