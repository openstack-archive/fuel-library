require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone'
require 'tempfile'

klass = Puppet::Provider::Keystone

class Puppet::Provider::Keystone
  @credentials = Puppet::Provider::Openstack::CredentialsV3.new

  def self.reset
    @admin_endpoint = nil
    @tenant_hash    = nil
    @admin_token    = nil
    @keystone_file  = nil
    @domain_id_to_name = nil
    @default_domain_id = nil
    @domain_hash = nil
  end
end

describe Puppet::Provider::Keystone do

  after :each do
    klass.reset
  end

  describe 'when retrieving the security token' do
    it 'should return nothing if there is no keystone config file' do
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(false)
      expect(klass.get_admin_token).to be_nil
    end

    it 'should return nothing if the keystone config file does not have a DEFAULT section' do
      mock = {}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_token).to be_nil
    end

    it 'should fail if the keystone config file does not contain an admin token' do
      mock = {'DEFAULT' => {'not_a_token' => 'foo'}}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_token).to be_nil
    end

    it 'should parse the admin token if it is in the config file' do
      mock = {'DEFAULT' => {'admin_token' => 'foo'}}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_token).to eq('foo')
    end

    it 'should use the specified bind_host in the admin endpoint' do
      mock = {'DEFAULT' => {'admin_bind_host' => '192.168.56.210', 'admin_port' => '35357' }}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_endpoint).to eq('http://192.168.56.210:35357/v3/')
    end

    it 'should use localhost in the admin endpoint if bind_host is 0.0.0.0' do
      mock = {'DEFAULT' => { 'admin_bind_host' => '0.0.0.0', 'admin_port' => '35357' }}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_endpoint).to eq('http://127.0.0.1:35357/v3/')
    end

    it 'should use [::1] in the admin endpoint if bind_host is ::0' do
      mock = {'DEFAULT' => { 'admin_bind_host' => '::0', 'admin_port' => '35357' }}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_endpoint).to eq('http://[::1]:35357/v3/')
    end

    it 'should use localhost in the admin endpoint if bind_host is unspecified' do
      mock = {'DEFAULT' => { 'admin_port' => '35357' }}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_endpoint).to eq('http://127.0.0.1:35357/v3/')
    end

    it 'should use https if ssl is enabled' do
      mock = {'DEFAULT' => {'admin_bind_host' => '192.168.56.210', 'admin_port' => '35357' }, 'ssl' => {'enable' => 'True'}}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_endpoint).to eq('https://192.168.56.210:35357/v3/')
    end

    it 'should use http if ssl is disabled' do
      mock = {'DEFAULT' => {'admin_bind_host' => '192.168.56.210', 'admin_port' => '35357' }, 'ssl' => {'enable' => 'False'}}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_endpoint).to eq('http://192.168.56.210:35357/v3/')
    end

    it 'should use the defined admin_endpoint if available' do
      mock = {'DEFAULT' => {'admin_endpoint' => 'https://keystone.example.com' }, 'ssl' => {'enable' => 'False'}}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_endpoint).to eq('https://keystone.example.com/v3/')
    end

    it 'should handle an admin_endpoint with a trailing slash' do
      mock = {'DEFAULT' => {'admin_endpoint' => 'https://keystone.example.com/' }, 'ssl' => {'enable' => 'False'}}
      File.expects(:exists?).with("/etc/keystone/keystone.conf").returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_endpoint).to eq('https://keystone.example.com/v3/')
    end

  end

  describe 'when using domains' do
    it 'name_and_domain should return the resource domain' do
      expect(klass.name_and_domain('foo::in_name', 'from_resource', 'default')).to eq(['foo', 'from_resource'])
    end
    it 'name_and_domain should return the default domain' do
      expect(klass.name_and_domain('foo', nil, 'default')).to eq(['foo', 'default'])
    end
    it 'name_and_domain should return the domain part of the name' do
      expect(klass.name_and_domain('foo::in_name', nil, 'default')).to eq(['foo', 'in_name'])
    end
    it 'should return the default domain name using the default_domain_id from keystone.conf' do
      ENV['OS_USERNAME']     = 'test'
      ENV['OS_PASSWORD']     = 'abc123'
      ENV['OS_PROJECT_NAME'] = 'test'
      ENV['OS_AUTH_URL']     = 'http://127.0.0.1:35357/v3'
      mock = {
        'DEFAULT' => {
          'admin_endpoint' => 'http://127.0.0.1:35357',
          'admin_token'    => 'admin_token'
        },
        'identity' => {'default_domain_id' => 'somename'}
      }
      File.expects(:exists?).with('/etc/keystone/keystone.conf').returns(true)
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.expects(:openstack)
           .with('domain', 'list', '--quiet', '--format', 'csv', [])
           .returns('"ID","Name","Enabled","Description"
"somename","SomeName",True,"default domain"
')
      expect(klass.name_and_domain('foo')).to eq(['foo', 'SomeName'])
    end
    it 'should return Default if default_domain_id is not configured' do
      ENV['OS_USERNAME']     = 'test'
      ENV['OS_PASSWORD']     = 'abc123'
      ENV['OS_PROJECT_NAME'] = 'test'
      ENV['OS_AUTH_URL']     = 'http://127.0.0.1:35357/v3'
      mock = {}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      File.expects(:exists?).with('/etc/keystone/keystone.conf').returns(true)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.expects(:openstack)
           .with('domain', 'list', '--quiet', '--format', 'csv', [])
           .returns('"ID","Name","Enabled","Description"
"default","Default",True,"default domain"
')
      expect(klass.name_and_domain('foo')).to eq(['foo', 'Default'])
    end
  end
end
