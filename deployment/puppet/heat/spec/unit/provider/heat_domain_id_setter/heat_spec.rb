require 'spec_helper'
require 'puppet'
require 'puppet/type/heat_domain_id_setter'

provider_class = Puppet::Type.type(:heat_domain_id_setter).provider(:ruby)

# used to simulate an authentication response from Keystone
# (POST v2.0/tokens)
auth_response = {
    'access' => {
        'token' => {
            'id' => 'TOKEN',
        }
    }
}

# used to simulate a response to GET v3/domains
domains_response = {
    'domains' => [
        {
            'name' => 'heat',
            'id'   => 'UUID_HEAT'
        },
        {
            'name' => 'multiple_matches_domain',
            'id'   => 'UUID1'
        },
        {
            'name' => 'multiple_matches_domain',
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

describe 'Puppet::Type.type(:heat_keystone_domain_id_setter)' do
    let :params do
        {
            :name             => 'heat_domain_id',
            :ensure           => 'present',
            :domain_name      => 'heat',
            :auth_url         => 'http://127.0.0.1:35357/v2.0',
            :auth_username    => 'admin',
            :auth_password    => 'admin_passwd',
            :auth_tenant_name => 'admin',
        }
    end

    it 'should have a non-nil provider' do
        expect(provider_class).not_to be_nil
    end

    context 'when url is correct' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
                to_return(:status => 200,
                          :body => auth_response.to_json,
                          :headers => {})
            stub_request(:get, "http://127.0.0.1:35357/v3/domains").
                with(:headers => {'X-Auth-Token'=>'TOKEN'}).
                to_return(:status => 200,
                          :body => domains_response.to_json,
                          :headers => {})
        end

        it 'should create a resource' do
            resource = Puppet::Type::Heat_domain_id_setter.new(params)
            provider = provider_class.new(resource)
            expect(provider.exists?).to be_false
            expect(provider.create).to be_nil
        end
    end

    # What happens if we ask for a domain that does not exist?
    context 'when domain cannot be found' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
                to_return(:status => 200,
                          :body => auth_response.to_json,
                          :headers => {})
            stub_request(:get, "http://127.0.0.1:35357/v3/domains").
                with(:headers => {'X-Auth-Token'=>'TOKEN'}).
                to_return(:status => 200,
                          :body => domains_response.to_json,
                          :headers => {})

            params.merge!(:domain_name => 'bad_domain_name')
        end

        it 'should receive an api error' do
            resource = Puppet::Type::Heat_domain_id_setter.new(params)
            provider = provider_class.new(resource)
            expect(provider.exists?).to be_false
            expect { provider.create }.to raise_error KeystoneAPIError, /Unable to find matching domain/
        end
    end

    # What happens if we ask for a domain name that results in multiple
    # matches?
    context 'when there are multiple matching domains' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").
                to_return(:status => 200,
                          :body => auth_response.to_json,
                          :headers => {})
            stub_request(:get, "http://127.0.0.1:35357/v3/domains").
                with(:headers => {'X-Auth-Token'=>'TOKEN'}).
                to_return(:status => 200,
                          :body => domains_response.to_json,
                          :headers => {})

            params.merge!(:domain_name => 'multiple_matches_domain')
        end

        it 'should receive an api error' do
            resource = Puppet::Type::Heat_domain_id_setter.new(params)
            provider = provider_class.new(resource)
            expect(provider.exists?).to be_false
            expect { provider.create }.to raise_error KeystoneAPIError, /Found multiple matches for domain name/
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
            resource = Puppet::Type::Heat_domain_id_setter.new(params)
            provider = provider_class.new(resource)
            expect(provider.exists?).to be_false
            expect { provider.create }.to raise_error KeystoneAPIError
        end
    end

    # What happens if the server is not listening?
    context 'when keystone server is unavailable' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").to_raise Errno::ECONNREFUSED
        end

        it 'should receive a connection error' do
            resource = Puppet::Type::Heat_domain_id_setter.new(params)
            provider = provider_class.new(resource)
            expect(provider.exists?).to be_false
            expect { provider.create }.to raise_error KeystoneConnectionError
        end
    end

    # What happens if we mistype the hostname?
    context 'when keystone server is unknown' do
        before :each do
            stub_request(:post, "http://127.0.0.1:35357/v2.0/tokens").to_raise SocketError, 'getaddrinfo: Name or service not known'
        end

        it 'should receive a connection error' do
            resource = Puppet::Type::Heat_domain_id_setter.new(params)
            provider = provider_class.new(resource)
            expect(provider.exists?).to be_false
            expect { provider.create }.to raise_error KeystoneConnectionError
        end
    end

end
