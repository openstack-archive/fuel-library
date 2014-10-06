require 'spec_helper'
require File.join(File.dirname(__FILE__), '../lib/base')
require File.join(File.dirname(__FILE__), '../lib/mysql')
require File.join(File.dirname(__FILE__), '../lib/migration')

class MigrationTest
  include Base
  include MySQL
  include Migration
end

describe MigrationTest do
  before :each do
    @class = subject
    @class.dry_run = true
    @class.stubs(:log).returns true
  end

  context 'Murano' do
    before :each do
      @class.stubs(:run).returns true
      @class.stubs(:mysql_database_exists?).returns true
    end

    it 'dumps old murano database' do
      @class.stubs(:timestamp).returns '1'
      database = 'murano'
      dump_file = File.join '/var/lib', 'murano-database-dump-1.sql.gz'
      @class.expects(:mysql_dump).with database, dump_file
      @class.recreate_murano_database
    end

    it 'drops old murano database' do
      @class.expects(:drop_mysql_database).with 'murano'
      @class.recreate_murano_database
    end

    it 'creates a new murano database' do
      @class.expects(:create_mysql_database).with 'murano'
      @class.recreate_murano_database
    end

    it 'runs db_sync and upgrade' do
      @class.expects(:run).with { |cmd| cmd.include? 'db-sync'}
      @class.expects(:run).with { |cmd| cmd.include? 'upgrade'}
      @class.recreate_murano_database
    end

    it 'does nothing if there is no murano database in the first place' do
      @class.stubs(:mysql_database_exists?).returns false
      @class.expects(:mysql_dump).never
      @class.expects(:drop_mysql_database).never
      @class.expects(:create_mysql_database).never
      @class.recreate_murano_database
    end

  end

end