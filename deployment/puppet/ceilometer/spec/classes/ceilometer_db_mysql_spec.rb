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
      :charset      => 'utf8',
      :collate      => 'utf8_general_ci',
    }
  end

  shared_examples_for 'ceilometer mysql database' do

    context 'when omiting the required parameter password' do
      before { params.delete(:password) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    it 'creates a mysql database' do
      is_expected.to contain_openstacklib__db__mysql( params[:dbname] ).with(
        :user          => params[:user],
        :password_hash => '*58C036CDA51D8E8BBBBF2F9EA5ABF111ADA444F0',
        :host          => params[:host],
        :charset       => params[:charset]
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

  end
end
