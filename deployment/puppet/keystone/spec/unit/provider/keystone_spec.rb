require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone'


klass = Puppet::Provider::Keystone

describe Puppet::Provider::Keystone do

  describe 'when retrieving the security token' do

    after :each do
      klass.instance_variable_set(:@keystone_file, nil)
    end

    it 'should fail if there is no keystone config file' do
      mock = nil
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect do
        klass.get_admin_token
      end.to raise_error(Puppet::Error, /Keystone types will not work/)
    end

    it 'should fail if the keystone config file does not have a DEFAULT section' do
      mock = {}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect do

        klass.get_admin_token
      end.to raise_error(Puppet::Error, /Keystone types will not work/)
    end

    it 'should fail if the keystone config file does not contain an admin token' do
      mock = {'DEFAULT' => {'not_a_token' => 'foo'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect do
       klass.get_admin_token
      end.to raise_error(Puppet::Error, /Keystone types will not work/)
    end

    it 'should parse the admin token if it is in the config file' do
      mock = {'DEFAULT' => {'admin_token' => 'foo'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_token.should == 'foo'
    end

  end

end
