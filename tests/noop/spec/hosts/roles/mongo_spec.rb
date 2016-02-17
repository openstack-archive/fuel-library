require 'spec_helper'
require 'shared-examples'
manifest = 'roles/mongo.pp'

describe manifest do

  shared_examples 'catalog' do
    debug = Noop.hiera 'debug'
    use_syslog = Noop.hiera 'use_syslog'
    ceilometer_hash = Noop.hiera_structure 'ceilometer'
    mongodb_port = Noop.hiera('mongodb_port', '27017')
    oplog_size = Noop.hiera('mongo/oplog_size', '10240')
    profile = Noop.hiera('mongo/profile', '1')
    directoryperdb = Noop.hiera('mongo/directoryperdb', true)

    it 'should configure MongoDB only with replica set' do
      should contain_class('mongodb::server').with('replset' => 'ceilometer')
    end

    it 'should configure MongoDB with authentication enabled' do
      should contain_class('mongodb::server').with('auth' => 'true')
      should contain_class('mongodb::server').with('create_admin' => 'true')
      should contain_class('mongodb::server').with('store_creds' => 'true')
      should contain_file("#{facts[:root_home]}/.mongorc.js").with('ensure' => 'present')
    end

    it 'should configure verbosity level for MongoDB' do
      if debug
        should contain_class('mongodb::server').with('verbositylevel' => 'vv')
      else
        should contain_class('mongodb::server').with('verbositylevel' => 'v')
      end
    end

    it 'should use astute keyfile for replica setup' do
      should contain_class('mongodb::server').with('keyfile' => '/var/lib/astute/mongodb/mongodb.key')
    end

    it 'should not write logs to file if syslog is enabled' do
      if use_syslog
        should contain_class('mongodb::server').with('logpath' => 'false')
      end
    end

    it 'should configure oplog size for local database' do
      should contain_class('mongodb::server').with('oplog_size' => oplog_size)
    end

    it 'should capture data regarding performance' do
      should contain_class('mongodb::server').with('profile' => profile)
   end

    it 'should store each database in separate directory' do
      should contain_class('mongodb::server').with('directoryperdb' => directoryperdb)
    end

  end

  test_ubuntu_and_centos manifest
end

