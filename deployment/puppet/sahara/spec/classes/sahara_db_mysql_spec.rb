#
# Unit tests for sahara::db::mysql
#
require 'spec_helper'

describe 'sahara::db::mysql' do

  let :pre_condition do
    ['include mysql::server']
  end

  let :params do
    { :dbname        => 'sahara',
      :password      => 's3cr3t',
      :user          => 'sahara',
      :charset       => 'utf8',
      :collate       => 'utf8_general_ci',
      :host          => '127.0.0.1',
    }
  end

  shared_examples_for 'sahara mysql database' do

    context 'when omiting the required parameter password' do
      before { params.delete(:password) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    it 'creates a mysql database' do
      is_expected.to contain_openstacklib__db__mysql('sahara').with(
        :user          => params[:user],
        :dbname        => params[:dbname],
        :password_hash => '*58C036CDA51D8E8BBBBF2F9EA5ABF111ADA444F0',
        :host          => params[:host],
        :charset       => params[:charset]
      )
    end

    context 'overriding allowed_hosts param to array' do
      before :each do
        params.merge!(
          :allowed_hosts  => ['127.0.0.1','%']
        )
      end

      it {
        is_expected.to contain_openstacklib__db__mysql('sahara').with(
          :user          => params[:user],
          :dbname        => params[:dbname],
          :password_hash => '*58C036CDA51D8E8BBBBF2F9EA5ABF111ADA444F0',
          :host          => params[:host],
          :charset       => params[:charset],
          :allowed_hosts => ['127.0.0.1','%']
      )}
    end

    context 'overriding allowed_hosts param to string' do
      before :each do
        params.merge!(
          :allowed_hosts  => '192.168.1.1'
        )
      end

      it {
        is_expected.to contain_openstacklib__db__mysql('sahara').with(
          :user          => params[:user],
          :dbname        => params[:dbname],
          :password_hash => '*58C036CDA51D8E8BBBBF2F9EA5ABF111ADA444F0',
          :host          => params[:host],
          :charset       => params[:charset],
          :allowed_hosts => '192.168.1.1'
      )}
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'sahara mysql database'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'sahara mysql database'
  end
end
