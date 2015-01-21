# Load libraries from aviator here to simulate how they live together in a real puppet run
$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'modules', 'aviator', 'lib'))
require 'puppet'
require 'vcr'
require 'spec_helper'
require 'puppet/provider/aviator'


describe Puppet::Provider::Aviator do

  before(:each) do
    ENV['OS_USERNAME']    = nil
    ENV['OS_PASSWORD']    = nil
    ENV['OS_TENANT_NAME'] = nil
    ENV['OS_AUTH_URL']    = nil
  end

  let(:log_file) { '/tmp/aviator_spec.log' }

  let(:type) do
    Puppet::Type.newtype(:test_resource) do
      newparam(:name, :namevar => true)
      newparam(:auth)
      newparam(:log_file)
    end
  end


  shared_examples 'creating a session using environment variables' do
    it 'creates an authenticated session' do
      ENV['OS_USERNAME']    = 'admin'
      ENV['OS_PASSWORD']    = 'fyby-tet'
      ENV['OS_TENANT_NAME'] = 'admin'
      ENV['OS_AUTH_URL']    = 'http://192.168.11.4:35357/v2.0'
      response = nil
      VCR.use_cassette('aviator/session/with_password') do
        session = provider.session
        response = session.identity_service.request(:list_tenants, :session_data => provider.session_data)
      end
      expect(response.status).to eq(200)
    end
  end

  shared_examples 'creating a session using a service token from keystone.conf' do
    it 'creates an unauthenticated session' do
      data = "[DEFAULT]\nadmin_token=sosp-kyl\nadmin_endpoint=http://192.168.11.4:35357/v2.0"
      response = nil
      VCR.use_cassette('aviator/session/with_token') do
        # Stubbing File.read produces inconsistent results because of how IniConfig
        # overrides the File class in some versions of Puppet.
        # Stubbing FileType.filetype(:flat) simplifies working with IniConfig
        Puppet::Util::FileType.filetype(:flat).any_instance.expects(:read).returns(StringIO.new(data).read)
        session = provider.session
        Puppet::Util::FileType.filetype(:flat).any_instance.unstub(:read)
        response = session.identity_service.request(:list_tenants, :session_data => provider.session_data)
      end

      expect(response.status).to eq(200)
    end
  end

  shared_examples 'it has no credentials' do
    it 'fails to authenticate' do
      expect{ provider.session }.to raise_error(Puppet::Error, /No credentials provided/)
    end
  end

  shared_examples 'making request with an existing session' do
   it 'makes a successful request' do
     VCR.use_cassette('aviator/request/with_session') do
       session = provider.session
       response = provider.request(session.identity_service, :list_tenants)
       expect(response.status).to eq(200)
     end
   end
  end

  shared_examples 'making request with injected session data' do
    it 'makes a successful request' do
      VCR.use_cassette('aviator/request/without_session') do
        session = provider.session
        response = provider.request(session.identity_service, :list_tenants)
        expect(response.status).to eq(200)
      end
    end
  end

  shared_examples 'making request with no session or session data' do
    it 'fails to make a request' do
      expect{ provider.request(nil, :list_tenants) }.to raise_error(Puppet::Error, /Cannot make a request/)
    end
  end

  describe '#session' do

    context 'with valid password credentials in parameters' do
      let(:resource_attrs) do
        {
          :name         => 'stubresource',
          :auth         => {
            'username'    => 'admin',
            'password'    => 'fyby-tet',
            'tenant_name' => 'admin',
            'host_uri'    => 'http://192.168.11.4:35357/v2.0',
          }
        }
      end

      it 'creates a session' do
        provider = Puppet::Provider::Aviator.new(type.new(resource_attrs))
        response = nil
        VCR.use_cassette('aviator/session/with_password') do
          session = provider.session
          response = session.identity_service.request(:list_tenants)
        end
        expect(response.status).to eq(200)
      end
    end

    context 'with valid openrc file in parameters' do
      data = "export OS_USERNAME='admin'\nexport OS_PASSWORD='fyby-tet'\nexport OS_TENANT_NAME='admin'\nexport OS_AUTH_URL='http://192.168.11.4:35357/v2.0'"
      let(:resource_attrs) do
        {
          :name         => 'stubresource',
          :auth         => {
            'openrc' => '/root/openrc'
          }
        }
      end

      it 'creates a session' do
        provider = Puppet::Provider::Aviator.new(type.new(resource_attrs))
        response = nil
        VCR.use_cassette('aviator/session/with_password') do
          File.expects(:open).with('/root/openrc').returns(StringIO.new(data))
          session = provider.session
          File.unstub(:open)  # Ignore File.open calls to cassette file
          response = session.identity_service.request(:list_tenants)
        end
        expect(response.status).to eq(200)
      end
    end

    context 'with valid service token in parameters' do
      let(:resource_attrs) do
        {
          :name         => 'stubresource',
          :auth         => {
            'service_token' => 'sosp-kyl',
            'host_uri'      => 'http://192.168.11.4:35357/v2.0'
          }
        }
      end

      subject(:session) do
        provider = Puppet::Provider::Aviator.new(type.new(resource_attrs))
        VCR.use_cassette('aviator/session/with_token') do
          session = provider.session
          response = session.identity_service.request(:list_tenants, :session_data => provider.session_data)
        end
      end

      it 'creates a session' do
        expect(session.status).to eq(200)
      end

    end

    context 'with valid password credentials in environment variables' do
      it_behaves_like 'creating a session using environment variables' do
        let(:resource_attrs) do
          {
            :name => 'stubresource',
          }
        end
        let(:provider) do
          Puppet::Provider::Aviator.new(type.new(resource_attrs))
        end
      end
    end

    context 'with valid service token in keystone.conf' do
      it_behaves_like 'creating a session using a service token from keystone.conf' do
        let(:resource_attrs) do
          {
            :name => 'stubresource',
          }
        end
        let(:provider) do
          Puppet::Provider::Aviator.new(type.new(resource_attrs))
        end
      end

    end

    context 'with no valid credentials' do
      it_behaves_like 'it has no credentials' do
        let(:resource_attrs) do
          {
            :name => 'stubresource',
          }
        end
        let(:provider) { Puppet::Provider::Aviator.new(type.new(resource_attrs)) }
      end
    end

  end


  describe '::session' do

    context 'with valid password credentials in environment variables' do
      it_behaves_like 'creating a session using environment variables' do
        let(:provider) { Puppet::Provider::Aviator.dup }
      end
    end

    context 'with valid service token in keystone.conf' do
      it_behaves_like 'creating a session using a service token from keystone.conf' do
        let(:provider) { Puppet::Provider::Aviator.dup }
      end
    end

    context 'with no valid credentials' do
      it_behaves_like 'it has no credentials' do
        let(:provider) { Puppet::Provider::Aviator.dup }
      end
    end
  end

  describe '#request' do
    context 'when a session exists' do
      it_behaves_like 'making request with an existing session' do
        let(:resource_attrs) do
          {
            :name         => 'stubresource',
            :auth         => {
              'username'    => 'admin',
              'password'    => 'fyby-tet',
              'tenant_name' => 'admin',
              'host_uri'    => 'http://192.168.11.4:35357/v2.0',
            }
          }
        end
        let (:provider) { Puppet::Provider::Aviator.new(type.new(resource_attrs)) }
      end
    end

    context 'when injecting session data' do
      let(:resource_attrs) do
        {
          :name         => 'stubresource',
          :auth         => {
            'service_token' => 'sosp-kyl',
            'host_uri'      => 'http://192.168.11.4:35357/v2.0'
          }
        }
      end
      let(:provider) { Puppet::Provider::Aviator.new(type.new(resource_attrs)) }
      it 'makes a successful request' do
        provider = Puppet::Provider::Aviator.new(type.new(resource_attrs))
        VCR.use_cassette('aviator/request/without_session') do
          session = provider.session
          response = provider.request(session.identity_service, :list_tenants)
          expect(response.status).to eq(200)
        end
      end
    end

    context 'when there is no session or session data' do
      it_behaves_like 'making request with no session or session data' do
        let(:resource_attrs) do
          {
            :name => 'stubresource',
          }
        end
        let(:provider) {Puppet::Provider::Aviator.new(type.new(resource_attrs)) }
      end
    end
  end

  describe '::request' do
    context 'when a session exists' do

      it_behaves_like 'making request with an existing session' do
        let(:provider) { provider = Puppet::Provider::Aviator.dup }
        before(:each) do
          ENV['OS_USERNAME']    = 'admin'
          ENV['OS_PASSWORD']    = 'fyby-tet'
          ENV['OS_TENANT_NAME'] = 'admin'
          ENV['OS_AUTH_URL']    = 'http://192.168.11.4:35357/v2.0'
        end
      end
    end

    context 'when injecting session data' do
      let(:session_data) do
        {
          :base_url      => 'http://192.168.11.4:35357/v2.0',
          :service_token => 'sosp-kyl'
        }
      end
      it 'makes a successful request' do
        provider = Puppet::Provider::Aviator.dup
        VCR.use_cassette('aviator/request/without_session') do
          session = ::Aviator::Session.new(:config => { :provider => 'openstack' }, :log_file => log_file)
          provider.session_data = session_data
          response = provider.request(session.identity_service, :list_tenants)
          expect(response.status).to eq(200)
        end
      end
    end

    context 'when there is no session or session data' do
      it_behaves_like 'making request with no session or session data' do
        let(:provider) { Puppet::Provider::Aviator.dup }
      end
    end
  end
end
