require 'spec_helper'

describe 'os_database_connection' do

  it 'refuses String' do
    is_expected.to run.with_params('foo').\
      and_raise_error(Puppet::ParseError, /Requires an hash/)
  end

  it 'refuses Array' do
    is_expected.to run.with_params(['foo']).\
      and_raise_error(Puppet::ParseError, /Requires an hash/)
  end

  it 'refuses without at least one argument' do
    is_expected.to run.with_params().\
      and_raise_error(Puppet::ParseError, /Wrong number of arguments/)
  end

  it 'refuses too many arguments' do
    is_expected.to run.with_params('foo', 'bar').\
      and_raise_error(Puppet::ParseError, /Wrong number of arguments/)
  end

  it 'fails if port is provided with missing host' do
    is_expected.to run.with_params({
        'dialect'  => 'sqlite',
        'database' => '/var/lib/keystone/keystone.db',
        'port'     => '3306',
        'charset'  => 'utf-8'
      }).and_raise_error(Puppet::ParseError, /host is required with port/)
  end

  context 'creates the correct connection URI' do

    it 'with all parameters' do
      is_expected.to run.with_params({
          'dialect'  => 'mysql',
          'host'     => '127.0.0.1',
          'port'     => '3306',
          'database' => 'test',
          'username' => 'guest',
          'password' => 's3cr3t',
          'charset'  => 'utf-8'
        }).and_return('mysql://guest:s3cr3t@127.0.0.1:3306/test?charset=utf-8')
    end

    it 'without port' do
      is_expected.to run.with_params({
          'dialect'  => 'mysql',
          'host'     => '127.0.0.1',
          'database' => 'test',
          'username' => 'guest',
          'password' => 's3cr3t',
          'charset'  => 'utf-8'
        }).and_return('mysql://guest:s3cr3t@127.0.0.1/test?charset=utf-8')
    end

    it 'without host and port' do
      is_expected.to run.with_params({
          'dialect'  => 'sqlite',
          'database' => '/var/lib/keystone/keystone.db',
          'charset'  => 'utf-8'
        }).and_return('sqlite:////var/lib/keystone/keystone.db?charset=utf-8')
    end

    it 'without username and password' do
      is_expected.to run.with_params({
          'dialect'  => 'mysql',
          'host'     => '127.0.0.1',
          'port'     => '3306',
          'database' => 'test',
          'charset'  => 'utf-8'
        }).and_return('mysql://127.0.0.1:3306/test?charset=utf-8')
    end

    it 'with username set to undef' do
      is_expected.to run.with_params({
          'dialect'  => 'mysql',
          'host'     => '127.0.0.1',
          'port'     => '3306',
          'database' => 'test',
          'username' => :undef,
          'charset'  => 'utf-8'
        }).and_return('mysql://127.0.0.1:3306/test?charset=utf-8')
    end

    it 'with username set to an empty string' do
      is_expected.to run.with_params({
          'dialect'  => 'mysql',
          'host'     => '127.0.0.1',
          'port'     => '3306',
          'database' => 'test',
          'username' => '',
          'charset'  => 'utf-8'
        }).and_return('mysql://127.0.0.1:3306/test?charset=utf-8')
    end

    it 'without password' do
      is_expected.to run.with_params({
          'dialect'  => 'mysql',
          'host'     => '127.0.0.1',
          'port'     => '3306',
          'database' => 'test',
          'username' => 'guest',
          'charset'  => 'utf-8'
        }).and_return('mysql://guest@127.0.0.1:3306/test?charset=utf-8')
    end

    it 'with password set to undef' do
      is_expected.to run.with_params({
          'dialect'  => 'mysql',
          'host'     => '127.0.0.1',
          'port'     => '3306',
          'database' => 'test',
          'username' => 'guest',
          'password' => :undef,
          'charset'  => 'utf-8'
        }).and_return('mysql://guest@127.0.0.1:3306/test?charset=utf-8')
    end

    it 'with password set to an empty string' do
      is_expected.to run.with_params({
          'dialect'  => 'mysql',
          'host'     => '127.0.0.1',
          'port'     => '3306',
          'database' => 'test',
          'username' => 'guest',
          'password' => '',
          'charset'  => 'utf-8'
        }).and_return('mysql://guest@127.0.0.1:3306/test?charset=utf-8')
    end
  end
end
