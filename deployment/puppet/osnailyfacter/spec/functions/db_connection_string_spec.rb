require 'spec_helper'

describe 'the db_connection_string function' do
  let (:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(
      Puppet::Parser::Functions.function('db_connection_string')
    ).to eq('function_db_connection_string')
  end

  it 'should raise an error if less then 4 params are provided' do
    expect {
      scope.function_db_connection_string([])
    }.to raise_error
  end

  it 'should return a valid mysql string when provided require arguments' do
    expect(
      scope.function_db_connection_string(['host', 'user', 'pass', 'db'])
    ).to eq 'mysql://user:pass@host/db'
  end

  it 'should return a valid pymysql string' do
    expect(
      scope.function_db_connection_string(['host', 'user', 'pass', 'db', 'pymysql'])
    ).to eq 'pymysql://user:pass@host/db'
  end

  it 'should return a valid mysql string with extra params' do
    expect(
      scope.function_db_connection_string(['host', 'user', 'pass', 'db', 'mysql', 'read_timeout=60'])
    ).to eq 'mysql://user:pass@host/db?read_timeout=60'
  end


  it 'should return a valid mysql string with multiple extra params' do
    expect(
      scope.function_db_connection_string(['host', 'user', 'pass', 'db', 'mysql', 'read_timeout=60&charset=utf-8'])
    ).to eq 'mysql://user:pass@host/db?read_timeout=60&charset=utf-8'
  end

end
