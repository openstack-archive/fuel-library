require 'spec_helper'

describe 'ceilometer::db::mysql' do

  let :pre_condition do
    'include mysql::server'
  end

  let :params do
    { :password     => 's3cr3t',
      :dbname       => 'ceilometer',
      :user         => 'ceilometer',
      :host         => 'localhost',
      :charset      => 'latin1',
      :collate      => 'latin1_swedish_ci',
      :mysql_module => '0.9',
    }
  end

  shared_examples_for 'ceilometer mysql database' do

    context 'when omiting the required parameter password' do
      before { params.delete(:password) }
      it { expect { should raise_error(Puppet::Error) } }
    end

    it 'creates a mysql database' do
      should contain_mysql__db( params[:dbname] ).with(
        :user     => params[:user],
        :password => params[:password],
        :host     => params[:host],
        :charset  => params[:charset],
        :require  => 'Class[Mysql::Config]'
      )
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'ceilometer mysql database'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'ceilometer mysql database'
  end

  describe "overriding allowed_hosts param to array" do
    let :facts do
      { :osfamily => "Debian" }
    end
    let :params do
      {
        :password       => 'ceilometerpass',
        :allowed_hosts  => ['localhost','%']
      }
    end

    it {should_not contain_ceilometer__db__mysql__host_access("localhost").with(
      :user     => 'ceilometer',
      :password => 'ceilometerpass',
      :database => 'ceilometer'
    )}
    it {should contain_ceilometer__db__mysql__host_access("%").with(
      :user     => 'ceilometer',
      :password => 'ceilometerpass',
      :database => 'ceilometer'
    )}
  end

  describe "overriding allowed_hosts param to string" do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    let :params do
      {
        :password       => 'ceilometerpass2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

    it {should contain_ceilometer__db__mysql__host_access("192.168.1.1").with(
      :user     => 'ceilometer',
      :password => 'ceilometerpass2',
      :database => 'ceilometer'
    )}
  end

  describe "overriding allowed_hosts param equals to host param " do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    let :params do
      {
        :password       => 'ceilometerpass2',
        :allowed_hosts  => 'localhost'
      }
    end

    it {should_not contain_ceilometer__db__mysql__host_access("localhost").with(
      :user     => 'ceilometer',
      :password => 'ceilometerpass2',
      :database => 'ceilometer'
    )}
  end
end
