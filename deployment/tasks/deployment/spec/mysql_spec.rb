require 'spec_helper'
require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/mysql')

class MySQLTest
  include Base
  include MySQL
end

describe MySQLTest do
  before :each do
    @class = subject
    @class.dry_run = true
    @class.stubs(:log).returns true
  end

  it 'can run a query' do
    @class.expects(:run).with %q(mysql -Be 'select * from test')
    @class.mysql_query %q(select * from test)
    @class.expects(:run).with %q(mysql -Be 'select * from test"test')
    @class.mysql_query %q(select * from test'test)
  end

  it 'can check if a database exists' do
    @class.expects(:mysql_query).with(%q(show create database `test`)).returns ['', 0]
    expect(@class.mysql_database_exists?('test')).to be_truthy
    @class.expects(:mysql_query).with(%q(show create database `test`)).returns ['', 1]
    expect(@class.mysql_database_exists?('test')).to be_falsey
  end

  it 'can drop a database' do
    @class.expects(:mysql_query).with(%q(drop database `test`)).returns ['', 0]
    expect(@class.drop_mysql_database('test')).to be_truthy
  end

  it 'can create a database' do
    @class.expects(:mysql_query).with(%q(create database `test` default character set utf8)).returns ['', 0]
    expect(@class.create_mysql_database('test')).to be_truthy
  end

  it 'can dump a database' do
    @class.expects(:run).with(%q(mysqldump --default-character-set=utf8 --single-transaction 'test' | gzip > 'test_dump.sql.gz')).returns ['', 0]
    expect(@class.mysql_dump('test', 'test_dump.sql.gz')).to be_truthy
  end

  it 'can restore a database' do
    @class.expects(:run).with(%q(cat 'test_dump.sql.gz' | gunzip | mysql --default-character-set=utf8 'test')).returns ['', 0]
    expect(@class.mysql_restore('test', 'test_dump.sql.gz')).to be_truthy
  end


end