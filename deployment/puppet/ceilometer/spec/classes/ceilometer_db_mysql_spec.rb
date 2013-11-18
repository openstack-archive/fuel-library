require 'spec_helper'

describe 'ceilometer::db::mysql' do

  let :pre_condition do
    'include mysql::server'
  end

  let :params do
    { :password  => 's3cr3t',
      :dbname    => 'ceilometer',
      :user      => 'ceilometer',
      :host      => 'localhost',
      :charset   => 'latin1'
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
end
