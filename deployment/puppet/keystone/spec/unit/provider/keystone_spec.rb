require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone'
require 'tempfile'


klass = Puppet::Provider::Keystone

describe Puppet::Provider::Keystone do

  after :each do
    klass.reset
  end


  describe 'when retrieving the security token' do

    it 'should fail if there is no keystone config file' do
      ini_file = Puppet::Util::IniConfig::File.new
      t = Tempfile.new('foo')
      path = t.path
      t.unlink
      ini_file.read(path)
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

    it 'should use the specified bind_host in the admin endpoint' do
      mock = {'DEFAULT' => {'bind_host' => '192.168.56.210', 'admin_port' => '35357' }}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'http://192.168.56.210:35357/v2.0/'
    end

    it 'should use localhost in the admin endpoint if bind_host is 0.0.0.0' do
      mock = {'DEFAULT' => { 'bind_host' => '0.0.0.0', 'admin_port' => '35357' }}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'http://127.0.0.1:35357/v2.0/'
    end

    it 'should use localhost in the admin endpoint if bind_host is unspecified' do
      mock = {'DEFAULT' => { 'admin_port' => '35357' }}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'http://127.0.0.1:35357/v2.0/'
    end

    it 'should use https if ssl is enabled' do
      mock = {'DEFAULT' => {'bind_host' => '192.168.56.210', 'admin_port' => '35357' }, 'ssl' => {'enable' => 'True'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'https://192.168.56.210:35357/v2.0/'
    end

    it 'should use http if ssl is disabled' do
      mock = {'DEFAULT' => {'bind_host' => '192.168.56.210', 'admin_port' => '35357' }, 'ssl' => {'enable' => 'False'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'http://192.168.56.210:35357/v2.0/'
    end

    it 'should use the defined admin_endpoint if available' do
      mock = {'DEFAULT' => {'admin_endpoint' => 'https://keystone.example.com/v2.0/' }, 'ssl' => {'enable' => 'False'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'https://keystone.example.com/v2.0/'
    end

    describe 'when testing keystone connection retries' do

      ['(HTTP 400)',
       '[Errno 111] Connection refused',
       '503 Service Unavailable',
       'Max retries exceeded',
       'HTTP Unable to establish connection',
       'Unable to establish connection to http://127.0.0.1:35357/v2.0/OS-KSADM/roles'
       ].reverse.each do |valid_message|
        it "should retry when keystone is not ready with error #{valid_message}" do
          mock = {'DEFAULT' => {'admin_token' => 'foo'}}
          Puppet::Util::IniConfig::File.expects(:new).returns(mock)
          mock.expects(:read).with('/etc/keystone/keystone.conf')
          klass.expects(:sleep).with(10).returns(nil)
          klass.expects(:keystone).twice.with('--os-endpoint', 'http://127.0.0.1:35357/v2.0/', ['test_retries']).raises(Exception, valid_message).then.returns('')
          klass.auth_keystone('test_retries')
        end
      end
    end

  end

  describe 'when keystone cli has warnings' do
    it "should remove errors from results" do
      mock = {'DEFAULT' => {'admin_token' => 'foo'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.expects(
        :keystone
      ).with(
        '--os-endpoint',
        'http://127.0.0.1:35357/v2.0/',
        ['test_retries']
      ).returns("WARNING\n+-+-+\nWARNING")
      klass.auth_keystone('test_retries').should == "+-+-+\nWARNING"
    end
  end

  describe 'when parsing keystone objects' do
    it 'should parse valid output into a hash' do
      data = <<-EOT
+-------------+----------------------------------+
|   Property  |              Value               |
+-------------+----------------------------------+
| description |          default tenant          |
|   enabled   |               True               |
|      id     | b71040f47e144399b7f10182918b5e2f |
|     name    |               demo               |
+-------------+----------------------------------+
      EOT
      expected = {
        'description' => 'default tenant',
        'enabled'     => 'True',
        'id'          => 'b71040f47e144399b7f10182918b5e2f',
        'name'        => 'demo'
      }
      klass.parse_keystone_object(data).should == expected
    end
  end

end
