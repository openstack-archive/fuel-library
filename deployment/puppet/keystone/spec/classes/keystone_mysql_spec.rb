require 'spec_helper'

describe 'keystone::mysql' do

  let :facts do
    { :osfamily => 'Debian' }
  end

  let :param_defaults do
    {
      'password' => 'keystone_default_password',
      'dbname'   => 'keystone',
      'user'     => 'keystone_admin',
      'host'     => '127.0.0.1'
    }
  end

  [
    {},
    {
      'password' => 'password',
      'dbname'   => 'not_keystone',
      'user'     => 'dan',
      'host'     => '127.0.0.2'
    }
  ].each do |p|

    let :params do
      p
    end

    let :param_values do
      param_defaults.merge(p)
    end

    it { should contain_file('/var/lib/keystone/keystone.db').with(
      'ensure'    => 'absent',
      'subscribe' => 'Package[keystone]',
      'before'    => "Mysql::Db[#{param_values['dbname']}]"
    )}

    it { should contain_mysql__db(param_values['dbname']).with(
      'user'     => param_values['user'],
      'password' => param_values['password'],
      'host'     => param_values['host'],
      'charset'  => 'latin1',
      'require'  => 'Class[Mysql::Server]'
    )}
  end

end
