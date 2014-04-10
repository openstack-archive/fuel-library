require 'spec_helper'

describe 'heat::db::mysql' do
  let :facts do
    { :osfamily => 'RedHat' }
  end

  let :params do
    { :password  => 's3cr3t',
      :dbname    => 'heat',
      :user      => 'heat',
      :host      => 'localhost',
      :charset   => 'latin1'
    }
  end

  shared_examples_for 'heat mysql database' do

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

  describe "overriding allowed_hosts param to array" do
    let :params do
      {
        :password       => 'heatpass',
        :allowed_hosts  => ['localhost','%']
      }
    end

    it {should_not contain_heat__db__mysql__host_access("localhost").with(
      :user     => 'heat',
      :password => 'heatpass',
      :database => 'heat'
    )}
    it {should contain_heat__db__mysql__host_access("%").with(
      :user     => 'heat',
      :password => 'heatpass',
      :database => 'heat'
    )}
  end

  describe "overriding allowed_hosts param to string" do
    let :params do
      {
        :password       => 'heatpass2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

    it {should contain_heat__db__mysql__host_access("192.168.1.1").with(
      :user     => 'heat',
      :password => 'heatpass2',
      :database => 'heat'
    )}
  end

  describe "overriding allowed_hosts param equals to host param " do
    let :params do
      {
        :password       => 'heatpass2',
        :allowed_hosts  => 'localhost'
      }
    end

    it {should_not contain_heat__db__mysql__host_access("localhost").with(
      :user     => 'heat',
      :password => 'heatpass2',
      :database => 'heat'
    )}
  end
end
