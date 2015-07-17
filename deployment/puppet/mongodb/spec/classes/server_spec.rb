require 'spec_helper'

describe 'mongodb::server' do
  let :facts do
    {
      :osfamily        => 'Debian',
      :operatingsystem => 'Debian',
    }
  end

  context 'with defaults' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('mongodb::server::install').
        that_comes_before('Class[mongodb::server::config]') }
    it { is_expected.to contain_class('mongodb::server::config').
        that_comes_before('Class[mongodb::server::service]') }
    it { is_expected.to contain_class('mongodb::server::service') }
  end

  context 'with create_admin => true' do
    let(:params) do
      {
        :create_admin   => true,
        :admin_username => 'admin',
        :admin_password => 'password'
      }
    end
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('mongodb::server::install').
        that_comes_before('Class[mongodb::server::config]') }
    it { is_expected.to contain_class('mongodb::server::config').
        that_comes_before('Class[mongodb::server::service]') }
    it { is_expected.to contain_class('mongodb::server::service') }

    it {
        is_expected.to contain_mongodb_user('admin').with({
          'username' => 'admin',
          'ensure'   => 'present',
          'database' => 'admin',
          'roles'    => ['dbAdmin', 'dbOwner', 'userAdmin', 'userAdminAnyDatabase'],
          'tries'    => 10,
          'tag'      => 'admin'
        })
      }
  end

  context 'when deploying on Solaris' do
    let :facts do
      { :osfamily        => 'Solaris' }
    end
    it { expect { should raise_error(Puppet::Error) } }
  end

end
