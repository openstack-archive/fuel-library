require 'spec_helper'

describe 'keystone::db::mysql' do

  let :pre_condition do
    'include mysql::server'
  end

  let :facts do
    { :osfamily => 'Debian' }
  end

  let :param_defaults do
    {
      'password' => 'keystone_default_password',
      'dbname'   => 'keystone',
      'user'     => 'keystone_admin',
      'charset'  => 'latin1',
      'host'     => '127.0.0.1'
    }
  end

  [
    {},
    {
      'password' => 'password',
      'dbname'   => 'not_keystone',
      'user'     => 'dan',
      'host'     => '127.0.0.2',
      'charset'  => 'utf8'
    }
  ].each do |p|

    let :params do
      p
    end

    let :param_values do
      param_defaults.merge(p)
    end

    it { should contain_class('mysql::python') }

    it { should contain_mysql__db(param_values['dbname']).with(
      'user'     => param_values['user'],
      'password' => param_values['password'],
      'host'     => param_values['host'],
      'charset'  => param_values['charset'],
      'require'  => 'Class[Mysql::Server]'
    )}

  end

end
