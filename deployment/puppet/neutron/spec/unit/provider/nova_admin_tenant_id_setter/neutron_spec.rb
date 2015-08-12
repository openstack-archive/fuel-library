require 'spec_helper'
require 'puppet'
require 'puppet/type/nova_admin_tenant_id_setter'

provider_class = Puppet::Type.type(:nova_admin_tenant_id_setter).provider(:ruby)

# used to simulate an authentication response from Keystone
# (POST v2.0/tokens)
auth_response = {
    'access' => {
        'token' => {
            'id' => 'TOKEN',
        }
    }
}

# used to simulate a response to GET v2.0/tenants
tenants_response = {
    'tenants' => [
        {
            'name' => 'services',
            'id'   => 'UUID_SERVICES'
        },
        {
            'name' => 'multiple_matches_tenant',
            'id'   => 'UUID1'
        },
        {
            'name' => 'multiple_matches_tenant',
            'id'   => 'UUID2'
        },
    ]
}

# Stub for ini_setting resource
Puppet::Type.newtype(:ini_setting) do
end

# Stub for ini_setting provider
Puppet::Type.newtype(:ini_setting).provide(:ruby) do
    def create
    end
end

describe 'Puppet::Type.type(:nova_admin_tenant_id_setter)' do
    let :params do
        {
            :name             => 'nova_admin_tenant_id',
            :tenant_name      => 'services',
            :auth_username    => 'nova',
            :auth_password    => 'secret',
            :auth_tenant_name => 'admin',
            :auth_url         => 'http://127.0.0.1:35357/v2.0',
        }
    end

    let(:resource) do
      Puppet::Type::Nova_admin_tenant_id_setter.new(params)
    end

    let(:provider) do
      provider = provider_class.new(resource)
      provider.stubs(:retry_count).returns(3)
      provider.stubs(:retry_sleep).returns(0)
      provider
    end

    it 'should have a non-nil provider' do
      expect(provider_class).not_to be_nil
    end

    before(:each) do
      puppet_debug_override
    end

    context 'when url is correct' do

        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
                to_return(:status => 200,
                          :body => auth_response.to_json,
                          :headers => {})
            stub_request(:get, "http://127.0.0.1:35357/v2.0/tenants").
                with(:headers => {'X-Auth-Token'=>'TOKEN'}).
                to_return(:status => 200,
                          :body => tenants_response.to_json,
                          :headers => {})
        end

        it 'should create a resource' do
            expect(provider.exists?).to be_falsey
            expect(provider.create).to be_nil
        end

        context 'when tenant id already set' do
            it 'should create a resource, with exists? true' do
                mock = { 'DEFAULT' => { 'nova_admin_tenant_id' => 'UUID_SERVICES' } }
                Puppet::Util::IniConfig::File.expects(:new).returns(mock)
                mock.expects(:read).with('/etc/neutron/neutron.conf')

                expect(provider.exists?).to be_truthy
                expect(provider.create).to be_nil
            end
        end
    end

    # What happens if we ask for a tenant that does not exist?
    context 'when tenant cannot be found' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
                to_return(:status => 200,
                          :body => auth_response.to_json,
                          :headers => {})
            stub_request(:get, "http://127.0.0.1:35357/v2.0/tenants").
                with(:headers => {'X-Auth-Token'=>'TOKEN'}).
                to_return(:status => 200,
                          :body => tenants_response.to_json,
                          :headers => {})

            params.merge!(:tenant_name => 'bad_tenant_name')
        end

        it 'should receive an "Unable to find matching tenant" api error' do
            expect(provider.exists?).to be_falsey
            expect { provider.create }.to raise_error KeystoneAPIError, /Unable to find matching tenant/
        end

        it 'should retry get_tenant_id defined number of times' do
          provider.expects(:get_tenant_id_request).times(3).raises KeystoneAPIError, 'Unable to find matching tenant'
          expect { provider.create }.to raise_error KeystoneAPIError, /Unable to find matching tenant/
        end
    end

    # What happens if we ask for a tenant name that results in multiple
    # matches?
    context 'when there are multiple matching tenants' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
                to_return(:status => 200,
                          :body => auth_response.to_json,
                          :headers => {})
            stub_request(:get, "http://127.0.0.1:35357/v2.0/tenants").
                with(:headers => {'X-Auth-Token'=>'TOKEN'}).
                to_return(:status => 200,
                          :body => tenants_response.to_json,
                          :headers => {})

            params.merge!(:tenant_name => 'multiple_matches_tenant')
        end

        it 'should receive an "Found multiple matches" api error' do
            expect(provider.exists?).to be_falsey
            expect { provider.create }.to raise_error KeystoneAPIError, /Found multiple matches/
        end

        it 'should not retry get_tenant_id on this error' do
          provider.expects(:get_tenant_id_request).once.raises KeystoneAPIError, 'Found multiple matches'
          expect { provider.create }.to raise_error KeystoneAPIError, /Found multiple matches/
        end
    end

    # What happens if we pass a bad password?
    context 'when password is incorrect' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
                to_return(:status => 401,
                          :body => auth_response.to_json,
                          :headers => {})
        end

        it 'should receive an authentication error' do
            expect(provider.exists?).to be_falsey
            expect { provider.create }.to raise_error KeystoneAPIError, /Received error response from Keystone server/
        end

        it 'should retry get_tenant_id defined number of times' do
          provider.expects(:get_tenant_id_request).times(3).raises KeystoneAPIError, 'Received error response from Keystone server'
          expect { provider.create }.to raise_error KeystoneAPIError, /Received error response from Keystone server/
        end
    end

    # What happens if the server is not listening?
    context 'when keystone server is unavailable' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").to_raise Errno::ECONNREFUSED
        end

        it 'should receive a connection error' do
            expect(provider.exists?).to be_falsey
            expect { provider.create }.to raise_error KeystoneConnectionError, /Connection refused/
        end

        it 'should retry get_tenant_id defined number of times' do
          provider.expects(:get_tenant_id_request).times(3).raises KeystoneConnectionError, 'Connection refused'
          expect { provider.create }.to raise_error KeystoneConnectionError, /Connection refused/
        end
    end

    # What happens if we mistype the hostname?
    context 'when keystone server is unknown' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").to_raise SocketError.new 'getaddrinfo: Name or service not known'
        end

        it 'should receive a connection error' do
            expect(provider.exists?).to be_falsey
            expect { provider.create }.to raise_error KeystoneConnectionError, /Name or service not known/
        end

        it 'should retry get_tenant_id defined number of times' do
          provider.expects(:get_tenant_id_request).times(3).raises KeystoneAPIError, 'Name or service not known'
          expect { provider.create }.to raise_error KeystoneAPIError, /Name or service not known/
        end
    end

    context 'when using secure keystone endpoint' do
        before :each do
            params.merge!(:auth_url => "https://127.0.0.1:35357/v2.0")
            stub_request(:post, "https://127.0.0.1:35357/v2.0/tokens").
                to_return(:status => 200,
                          :body => auth_response.to_json,
                          :headers => {})
            stub_request(:get, "https://127.0.0.1:35357/v2.0/tenants").
                with(:headers => {'X-Auth-Token'=>'TOKEN'}).
                to_return(:status => 200,
                          :body => tenants_response.to_json,
                          :headers => {})
        end

        it 'should create a resource' do
            expect(provider.exists?).to be_falsey
            expect(provider.create).to be_nil
        end
    end

end

