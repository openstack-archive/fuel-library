require 'puppet'
require 'spec_helper'
require 'puppet/provider/openstack'
require 'puppet/provider/openstack/auth'
require 'tempfile'

class Puppet::Provider::Openstack::AuthTester < Puppet::Provider::Openstack
  extend Puppet::Provider::Openstack::Auth
end

klass = Puppet::Provider::Openstack::AuthTester

describe Puppet::Provider::Openstack::Auth do

  let(:type) do
    Puppet::Type.newtype(:test_resource) do
      newparam(:name, :namevar => true)
      newparam(:log_file)
    end
  end

  let(:resource_attrs) do
    {
      :name => 'stubresource'
    }
  end

  let(:provider) do
    klass.new(type.new(resource_attrs))
  end

  before(:each) do
    ENV['OS_USERNAME']     = nil
    ENV['OS_PASSWORD']     = nil
    ENV['OS_PROJECT_NAME'] = nil
    ENV['OS_AUTH_URL']     = nil
    ENV['OS_TOKEN']        = nil
    ENV['OS_URL']          = nil
  end

  describe '#set_credentials' do
    it 'adds keys to the object' do
      credentials = Puppet::Provider::Openstack::CredentialsV2_0.new
      set = { 'OS_USERNAME'             => 'user',
              'OS_PASSWORD'             => 'secret',
              'OS_PROJECT_NAME'         => 'tenant',
              'OS_AUTH_URL'             => 'http://127.0.0.1:5000',
              'OS_TOKEN'                => 'token',
              'OS_URL'                  => 'http://127.0.0.1:35357',
              'OS_IDENTITY_API_VERSION' => '2.0',
              'OS_NOT_VALID'            => 'notvalid'
        }
      klass.set_credentials(credentials, set)
      expect(credentials.to_env).to eq(
        "OS_AUTH_URL"             => "http://127.0.0.1:5000",
        "OS_IDENTITY_API_VERSION" => '2.0',
        "OS_PASSWORD"             => "secret",
        "OS_PROJECT_NAME"         => "tenant",
        "OS_TOKEN"                => "token",
        "OS_URL"                  => "http://127.0.0.1:35357",
        "OS_USERNAME"             => "user")
    end
  end

  describe '#rc_filename' do
    it 'returns RCFILENAME' do
      expect(klass.rc_filename).to eq("#{ENV['HOME']}/openrc")
    end
  end

  describe '#get_os_from_env' do
    context 'with Openstack environment variables set' do
      it 'provides a hash' do
        ENV['OS_AUTH_URL']     = 'http://127.0.0.1:5000'
        ENV['OS_PASSWORD']     = 'abc123'
        ENV['OS_PROJECT_NAME'] = 'test'
        ENV['OS_USERNAME']     = 'test'
        response = klass.get_os_vars_from_env
        expect(response).to eq({
          "OS_AUTH_URL"     => "http://127.0.0.1:5000",
          "OS_PASSWORD"     => "abc123",
          "OS_PROJECT_NAME" => "test",
          "OS_USERNAME"     => "test"})
      end
    end
  end

  describe '#get_os_vars_from_rcfile' do
    context 'with a valid RC file' do
      it 'provides a hash' do
        mock = "export OS_USERNAME='test'\nexport OS_PASSWORD='abc123'\nexport OS_PROJECT_NAME='test'\nexport OS_AUTH_URL='http://127.0.0.1:5000'"
        filename = 'file'
        File.expects(:exists?).with('file').returns(true)
        File.expects(:open).with('file').returns(StringIO.new(mock))

        response = klass.get_os_vars_from_rcfile(filename)
        expect(response).to eq({
          "OS_AUTH_URL"     => "http://127.0.0.1:5000",
          "OS_PASSWORD"     => "abc123",
          "OS_PROJECT_NAME" => "test",
          "OS_USERNAME"     => "test"})
      end
    end

    context 'with an empty file' do
      it 'provides an empty hash' do
        filename = 'file'
        File.expects(:exists?).with(filename).returns(true)
        File.expects(:open).with(filename).returns(StringIO.new(""))

        response = klass.get_os_vars_from_rcfile(filename)
        expect(response).to eq({})
      end
    end
  end

  before(:each) do
    class Puppet::Provider::Openstack::AuthTester
      @credentials =  Puppet::Provider::Openstack::CredentialsV2_0.new
    end
  end

  describe '#request' do
    context 'with no valid credentials' do
      it 'fails to authenticate' do
        expect { klass.request('project', 'list', ['--long']) }.to raise_error(Puppet::Error::OpenstackAuthInputError, "Insufficient credentials to authenticate")
        expect(klass.instance_variable_get(:@credentials).to_env).to eq({})
      end
    end

    context 'with user credentials in env' do
      it 'is successful' do
        klass.expects(:get_os_vars_from_env)
             .returns({ 'OS_USERNAME'     => 'test',
                        'OS_PASSWORD'     => 'abc123',
                        'OS_PROJECT_NAME' => 'test',
                        'OS_AUTH_URL'     => 'http://127.0.0.1:5000',
                        'OS_NOT_VALID'    => 'notvalid' })
        klass.expects(:openstack)
             .with('project', 'list', '--quiet', '--format', 'csv', ['--long'])
             .returns('"ID","Name","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","test","Test tenant",True
')
        response = klass.request('project', 'list', ['--long'])
        expect(response.first[:description]).to eq("Test tenant")
        expect(klass.instance_variable_get(:@credentials).to_env).to eq({
          'OS_USERNAME'     => 'test',
          'OS_PASSWORD'     => 'abc123',
          'OS_PROJECT_NAME' => 'test',
          'OS_AUTH_URL'     => 'http://127.0.0.1:5000'
        })
      end
    end

    context 'with service token credentials in env' do
      it 'is successful' do
        klass.expects(:get_os_vars_from_env)
             .returns({ 'OS_TOKEN'     => 'test',
                        'OS_URL'       => 'http://127.0.0.1:5000',
                        'OS_NOT_VALID' => 'notvalid' })
        klass.expects(:openstack)
             .with('project', 'list', '--quiet', '--format', 'csv', ['--long'])
             .returns('"ID","Name","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","test","Test tenant",True
')
        response = klass.request('project', 'list', ['--long'])
        expect(response.first[:description]).to eq("Test tenant")
        expect(klass.instance_variable_get(:@credentials).to_env).to eq({
          'OS_TOKEN' => 'test',
          'OS_URL'   => 'http://127.0.0.1:5000',
        })
      end
    end

    context 'with a RC file containing user credentials' do
      it 'is successful' do
        # return incomplete creds from env
        klass.expects(:get_os_vars_from_env)
             .returns({ 'OS_USERNAME' => 'incompleteusername',
                        'OS_AUTH_URL' => 'incompleteauthurl' })
        mock = "export OS_USERNAME='test'\nexport OS_PASSWORD='abc123'\nexport OS_PROJECT_NAME='test'\nexport OS_AUTH_URL='http://127.0.0.1:5000'\nexport OS_NOT_VALID='notvalid'"
        File.expects(:exists?).with("#{ENV['HOME']}/openrc").returns(true)
        File.expects(:open).with("#{ENV['HOME']}/openrc").returns(StringIO.new(mock))
        klass.expects(:openstack)
             .with('project', 'list', '--quiet', '--format', 'csv', ['--long'])
             .returns('"ID","Name","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","test","Test tenant",True
')
        response = provider.class.request('project', 'list', ['--long'])
        expect(response.first[:description]).to eq("Test tenant")
        expect(klass.instance_variable_get(:@credentials).to_env).to eq({
          'OS_USERNAME'     => 'test',
          'OS_PASSWORD'     => 'abc123',
          'OS_PROJECT_NAME' => 'test',
          'OS_AUTH_URL'     => 'http://127.0.0.1:5000'
        })
      end
    end

    context 'with a RC file containing service token credentials' do
      it 'is successful' do
        # return incomplete creds from env
        klass.expects(:get_os_vars_from_env)
             .returns({ 'OS_TOKEN' => 'incomplete' })
        mock = "export OS_TOKEN='test'\nexport OS_URL='abc123'\nexport OS_NOT_VALID='notvalid'\n"
        File.expects(:exists?).with("#{ENV['HOME']}/openrc").returns(true)
        File.expects(:open).with("#{ENV['HOME']}/openrc").returns(StringIO.new(mock))
        klass.expects(:openstack)
             .with('project', 'list', '--quiet', '--format', 'csv', ['--long'])
             .returns('"ID","Name","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","test","Test tenant",True
')
        response = klass.request('project', 'list', ['--long'])
        expect(response.first[:description]).to eq("Test tenant")
        expect(klass.instance_variable_get(:@credentials).to_env).to eq({
          'OS_TOKEN' => 'test',
          'OS_URL'   => 'abc123',
        })
      end
    end
  end
end
