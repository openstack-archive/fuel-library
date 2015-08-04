require 'spec_helper'
require 'shared-examples'
manifest = 'roles/mongo.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :file
    MockFunction.new(:file) do |function|
      allow(function).to receive(:call).with(['/var/lib/astute/mongodb/mongodb.key']).and_return('key')
    end
  end

  shared_examples 'catalog' do
    debug = Noop.hiera 'debug'
    use_syslog = Noop.hiera 'use_syslog'
    ceilometer_hash = Noop.hiera_structure 'ceilometer'
    nodes_hash = Noop.hiera 'nodes'

    it 'should configure MongoDB only with replica set' do
      should contain_class('mongodb::server').with('replset' => 'ceilometer')
    end

    it 'should configure MongoDB with authentication enabled' do
      should contain_class('mongodb::server').with('auth' => 'true')
    end

    it 'should configure verbosity level for MongoDB' do
      if debug
        should contain_class('mongodb::server').with('verbositylevel' => 'vv')
      else
        should contain_class('mongodb::server').with('verbositylevel' => 'v')
      end
    end

    it 'should create keyfile for replica setup' do
      should contain_class('mongodb::server').with('keyfile' => '/etc/mongodb.key')
    end

    it 'should not write logs to file if syslog is enabled' do
      if use_syslog
        should contain_class('mongodb::server').with('logpath' => 'false')
      end
    end

    it 'should configure oplog size for local database' do
      should contain_class('mongodb::server').with('oplog_size' => '10240')
    end

    it 'should capture data regarding performance' do
      should contain_class('mongodb::server').with('profile' => '1')
   end

    it 'should store each database in separate directory' do
      should contain_class('mongodb::server').with('directoryperdb' => 'true')
    end

  end

  test_ubuntu_and_centos manifest
end

