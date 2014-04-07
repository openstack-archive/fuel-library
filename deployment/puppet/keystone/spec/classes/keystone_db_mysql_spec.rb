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

  let :param_defaults do
    {
      'password'      => 'keystone_default_password',
      'dbname'        => 'keystone',
      'user'          => 'keystone',
      'charset'       => 'latin1',
      'host'          => '127.0.0.1',
      'allowed_hosts' => ['127.0.0.%', '192.168.1.%']
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
      'require'  => 'Class[Mysql::Config]'
    )}

  end
  describe "overriding allowed_hosts param to array" do
    let :params do
      {
        :password       => 'keystonepass',
        :allowed_hosts  => ['127.0.0.1','%']
      }
    end

    it {should_not contain_keystone__db__mysql__host_access("127.0.0.1").with(
      :user     => 'keystone',
      :password => 'keystonepass',
      :database => 'keystone'
    )}
    it {should contain_keystone__db__mysql__host_access("%").with(
      :user     => 'keystone',
      :password => 'keystonepass',
      :database => 'keystone'
    )}
  end
  describe "overriding allowed_hosts param to string" do
    let :params do
      {
        :password       => 'keystonepass2',
        :allowed_hosts  => '192.168.1.1'
      }
    end

    it {should contain_keystone__db__mysql__host_access("192.168.1.1").with(
      :user     => 'keystone',
      :password => 'keystonepass2',
      :database => 'keystone'
    )}
  end

  describe "overriding allowed_hosts param equals to host param " do
    let :params do
      {
        :password       => 'keystonepass2',
        :allowed_hosts  => '127.0.0.1'
      }
    end

    it {should_not contain_keystone__db__mysql__host_access("127.0.0.1").with(
      :user     => 'keystone',
      :password => 'keystonepass2',
      :database => 'keystone'
    )}
  end

end
