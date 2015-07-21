require 'puppet'
require 'spec_helper'
require 'puppet/provider/openstack'
require 'puppet/provider/openstack/credentials'


describe Puppet::Provider::Openstack::Credentials do

  let(:creds) do
    creds = Puppet::Provider::Openstack::CredentialsV2_0.new
  end

  describe "#set with valid value" do
    it 'works with valid value' do
      expect(creds.class.defined?('auth_url')).to be_truthy
      creds.set('auth_url', 'http://localhost:5000/v2.0')
      expect(creds.auth_url).to eq('http://localhost:5000/v2.0')
    end
  end

  describe "#set with invalid value" do
    it 'works with invalid value' do
      expect(creds.class.defined?('foo')).to be_falsey
      creds.set('foo', 'junk')
      expect(creds.respond_to?(:foo)).to be_falsey
      expect(creds.instance_variable_defined?(:@foo)).to be_falsey
      expect { creds.foo }.to raise_error(NoMethodError, /undefined method/)
    end
  end

  describe '#service_token_set?' do
    context "with service credentials" do
      it 'is successful' do
        creds.token = 'token'
        creds.url = 'url'
        expect(creds.service_token_set?).to be_truthy
        expect(creds.user_password_set?).to be_falsey
      end

      it 'fails' do
        creds.token = 'token'
        expect(creds.service_token_set?).to be_falsey
        expect(creds.user_password_set?).to be_falsey
      end
    end
  end

  describe '#password_set?' do
    context "with user credentials" do
      it 'is successful' do
        creds.auth_url = 'auth_url'
        creds.password = 'password'
        creds.project_name = 'project_name'
        creds.username = 'username'
        expect(creds.user_password_set?).to be_truthy
        expect(creds.service_token_set?).to be_falsey
      end

      it 'fails' do
        creds.auth_url = 'auth_url'
        creds.password = 'password'
        creds.project_name = 'project_name'
        expect(creds.user_password_set?).to be_falsey
        expect(creds.service_token_set?).to be_falsey
      end
    end
  end

  describe '#set?' do
    context "without any credential" do
      it 'fails' do
        expect(creds.set?).to be_falsey
      end
    end
  end

  describe '#version' do
    it 'is version 2' do
      expect(creds.version).to eq('2.0')
    end
  end

  describe '#unset' do
    context "with all instance variables set" do
      it 'resets all but the identity_api_version' do
        creds.auth_url = 'auth_url'
        creds.password = 'password'
        creds.project_name = 'project_name'
        creds.username = 'username'
        creds.token = 'token'
        creds.url = 'url'
        creds.identity_api_version = 'identity_api_version'
        creds.unset
        expect(creds.auth_url).to eq('')
        expect(creds.password).to eq('')
        expect(creds.project_name).to eq('')
        expect(creds.username).to eq('')
        expect(creds.token).to eq('')
        expect(creds.url).to eq('')
        expect(creds.identity_api_version).to eq('identity_api_version')
        newcreds = Puppet::Provider::Openstack::CredentialsV3.new
        expect(newcreds.identity_api_version).to eq('3')
      end
    end
  end

  describe '#to_env' do
    context "with an exhaustive data set" do
      it 'successfully returns content' do
        creds.auth_url = 'auth_url'
        creds.password = 'password'
        creds.project_name = 'project_name'
        creds.username = 'username'
        creds.token = 'token'
        creds.url = 'url'
        creds.identity_api_version = 'identity_api_version'
        expect(creds.to_env).to eq({
          'OS_USERNAME'             => 'username',
          'OS_PASSWORD'             => 'password',
          'OS_PROJECT_NAME'         => 'project_name',
          'OS_AUTH_URL'             => 'auth_url',
          'OS_TOKEN'                => 'token',
          'OS_URL'                  => 'url',
          'OS_IDENTITY_API_VERSION' => 'identity_api_version'
        })
      end
    end
  end

  describe 'using v3' do
    let(:creds) do
      creds = Puppet::Provider::Openstack::CredentialsV3.new
    end
    describe 'with v3' do
      it 'uses v3 identity api' do
        creds.identity_api_version == '3'
      end
    end
    describe '#password_set? with username and project_name' do
      it 'is successful' do
        creds.auth_url = 'auth_url'
        creds.password = 'password'
        creds.project_name = 'project_name'
        creds.username = 'username'
        expect(creds.user_password_set?).to be_truthy
      end
    end
    describe '#password_set? with user_id and project_id' do
      it 'is successful' do
        creds.auth_url = 'auth_url'
        creds.password = 'password'
        creds.project_id = 'projid'
        creds.user_id = 'userid'
        expect(creds.user_password_set?).to be_truthy
      end
    end
  end
end
