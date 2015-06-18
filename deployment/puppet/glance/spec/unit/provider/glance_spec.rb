require 'puppet'
require 'spec_helper'
require 'puppet/provider/glance'
require 'tempfile'


klass = Puppet::Provider::Glance

describe Puppet::Provider::Glance do

  after :each do
    klass.reset
  end

  describe 'when retrieving the auth credentials' do

    it 'should fail if the glance config file does not have the expected contents' do
      mock = {}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/glance/glance-api.conf')
      expect do
        klass.glance_credentials
      end.to raise_error(Puppet::Error, /does not contain all required sections/)
    end

  describe 'when testing glance connection retries' do

      ['[Errno 111] Connection refused', '(HTTP 400)', 'HTTP Unable to establish connection'].reverse.each do |valid_message|
        it "should retry when glance is not ready with error #{valid_message}" do
          mock = {'keystone_authtoken' =>
            {
               'auth_host'         => '127.0.0.1',
               'auth_port'         => '35357',
               'auth_protocol'     => 'http',
               'admin_tenant_name' => 'foo',
               'admin_user'        => 'user',
               'admin_password'    => 'pass'
            },
                'DEFAULT' =>
            {
                'os_region_name' => 'SomeRegion',
            }
          }
          Puppet::Util::IniConfig::File.expects(:new).returns(mock)
          mock.expects(:read).with('/etc/glance/glance-api.conf')
          klass.expects(:sleep).with(10).returns(nil)
          klass.expects(:glance).twice.with(
            '--os-tenant-name',
            'foo',
            '--os-username',
            'user',
            '--os-password',
            'pass',
            '--os-region-name',
            'SomeRegion',
            '--os-auth-url',
            'http://127.0.0.1:35357/v2.0/',
            ['test_retries']
          ).raises(Exception, valid_message).then.returns('')
          klass.auth_glance('test_retries')
        end
      end
    end
  end
end
