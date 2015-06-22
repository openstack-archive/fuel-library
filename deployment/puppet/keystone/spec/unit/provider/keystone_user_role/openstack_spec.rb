require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_user_role/openstack'

provider_class = Puppet::Type.type(:keystone_user_role).provider(:openstack)

describe provider_class do

  shared_examples 'authenticated with environment variables' do
    ENV['OS_USERNAME']     = 'test'
    ENV['OS_PASSWORD']     = 'abc123'
    ENV['OS_PROJECT_NAME'] = 'test'
    ENV['OS_AUTH_URL']     = 'http://127.0.0.1:5000'
  end

  describe 'when updating a user\'s role' do
    it_behaves_like 'authenticated with environment variables' do
      let(:user_role_attrs) do
        {
          :name         => 'foo@foo',
          :ensure       => 'present',
          :roles        => ['foo', 'bar'],
        }
      end

      let(:resource) do
        Puppet::Type::Keystone_user_role.new(user_role_attrs)
      end

      let(:provider) do
        provider_class.new(resource)
      end

      before(:each) do
        provider.class.stubs(:openstack)
                      .with('user', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'foo'])
                      .returns('"ID","Name","Project","User"
"1cb05cfed7c24279be884ba4f6520262","foo","foo","foo"
')
      end

      describe '#create' do
        it 'adds all the roles to the user' do
          provider.class.stubs(:openstack)
                        .with('role', 'add', ['foo', '--project', 'foo', '--user', 'foo'])
          provider.class.stubs(:openstack)
                        .with('role', 'add', ['bar', '--project', 'foo', '--user', 'foo'])
          provider.class.stubs(:openstack)
                        .with('user role', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'foo'])
                        .returns('"ID","Name","Project","User"
"1cb05ed7c24279be884ba4f6520262","foo","foo","foo"
"2cb05ed7c24279be884ba4f6520262","bar","foo","foo"
')
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy' do
        it 'removes all the roles from a user' do
          provider.class.stubs(:openstack)
                        .with('user role', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'foo'])
                        .returns('"ID","Name","Project","User"')
          provider.class.stubs(:openstack)
                        .with('role', 'remove', ['foo', '--project', 'foo', '--user', 'foo'])
          provider.class.stubs(:openstack)
                        .with('role', 'remove', ['bar', '--project', 'foo', '--user', 'foo'])
          provider.destroy
          expect(provider.exists?).to be_falsey
        end

      end

      describe '#exists' do
        subject(:response) do
          provider.class.stubs(:openstack)
                        .with('user role', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'foo'])
                        .returns('"ID","Name","Project","User"
"1cb05ed7c24279be884ba4f6520262","foo","foo","foo"
')
          response = provider.exists?
        end

        it { is_expected.to be_truthy }

      end
    end
  end
end
