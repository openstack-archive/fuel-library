require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_user/openstack'

provider_class = Puppet::Type.type(:keystone_user).provider(:openstack)

describe provider_class do

  shared_examples 'authenticated with environment variables' do
    ENV['OS_USERNAME']     = 'test'
    ENV['OS_PASSWORD']     = 'abc123'
    ENV['OS_PROJECT_NAME'] = 'test'
    ENV['OS_AUTH_URL']     = 'http://127.0.0.1:5000'
  end

  let(:user_attrs) do
    {
      :name         => 'foo',
      :ensure       => :present,
      :enabled      => 'True',
      :password     => 'foo',
      :tenant       => 'foo',
      :email        => 'foo@example.com',
    }
  end

  let(:resource) do
    Puppet::Type::Keystone_user.new(user_attrs)
  end

  let(:provider) do
    provider_class.new(resource)
  end

  describe 'when managing a user' do
    it_behaves_like 'authenticated with environment variables' do
      describe '#create' do
        it 'creates a user' do
          provider.class.stubs(:openstack)
                        .with('user', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Project","Email","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo","foo@example.com",True
')
          provider.class.stubs(:openstack)
                        .with('user', 'create', '--format', 'shell', ['foo', '--enable', '--password', 'foo', '--project', 'foo', '--email', 'foo@example.com'])
                        .returns('email="foo@example.com"
enabled="True"
id="12b23f07d4a3448d8189521ab09610b0"
name="foo"
project_id="5e2001b2248540f191ff22627dc0c2d7"
username="foo"
')
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy' do
        it 'destroys a user' do
          provider.class.stubs(:openstack)
                        .with('user', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Project","Email","Enabled"')
          provider.class.stubs(:openstack)
                        .with('user', 'delete', [])
          provider.destroy
          expect(provider.exists?).to be_falsey
        end

      end

      describe '#exists' do
        context 'when user does not exist' do
          subject(:response) do
            provider.class.stubs(:openstack)
                          .with('user', 'list', '--quiet', '--format', 'csv', '--long')
                          .returns('"ID","Name","Project","Email","Enabled"')
            response = provider.exists?
          end

          it { is_expected.to be_falsey }
        end
      end

      describe '#instances' do
        it 'finds every user' do
          provider.class.stubs(:openstack)
                        .with('user', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Project","Email","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo","foo@example.com",True
')
          instances = Puppet::Type::Keystone_user::ProviderOpenstack.instances
          expect(instances.count).to eq(1)
        end
      end

      describe '#tenant' do
        it 'gets the tenant with default backend' do
          provider.class.stubs(:openstack)
                        .with('user', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Project","Email","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo","foo@example.com",True
')
          provider.class.stubs(:openstack)
                        .with('user role', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'foo'])
                        .returns('"ID","Name","Project","User"
"9fe2ff9ee4384b1894a90878d3e92bab","_member_","foo","foo"
')
          tenant = provider.tenant
          expect(tenant).to eq('foo')
        end

        it 'gets the tenant with LDAP backend' do
          provider.class.stubs(:openstack)
                        .with('user', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Project","Email","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","","foo@example.com",True
')
          provider.class.expects(:openstack)
                        .with('user role', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'foo'])
                        .returns('"ID","Name","Project","User"
"1cb05cfed7c24279be884ba4f6520262","foo","foo","foo"
')
          tenant = provider.tenant
          expect(tenant).to eq('foo')
        end
      end

      describe '#tenant=' do
        context 'when using default backend' do
          it 'sets the tenant' do
            provider.class.expects(:openstack)
                          .with('user', 'set', ['foo', '--project', 'bar'])
            provider.class.expects(:openstack)
                          .with('user role', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'bar'])
                          .returns('"ID","Name","Project","User"
"9fe2ff9ee4384b1894a90878d3e92bab","_member_","bar","foo"
')
            provider.tenant=('bar')
          end
        end

        context 'when using LDAP read-write backend' do
          it 'sets the tenant when _member_ role exists' do
            provider.class.expects(:openstack)
                          .with('user', 'set', ['foo', '--project', 'bar'])
            provider.class.expects(:openstack)
                          .with('user role', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'bar'])
                          .returns('')
            provider.class.expects(:openstack)
                          .with('role', 'show', '--format', 'shell', ['_member_'])
                          .returns('id="9fe2ff9ee4384b1894a90878d3e92bab"
name="_member_"
')
            provider.class.expects(:openstack)
                          .with('role', 'add', ['_member_', '--project', 'bar', '--user', 'foo'])
            provider.tenant=('bar')
          end
          it 'sets the tenant when _member_ role does not exist' do
            provider.class.expects(:openstack)
                          .with('user', 'set', ['foo', '--project', 'bar'])
            provider.class.expects(:openstack)
                          .with('user role', 'list', '--quiet', '--format', 'csv', ['foo', '--project', 'bar'])
                          .returns('')
            provider.class.expects(:openstack)
                          .with('role', 'show', '--format', 'shell', ['_member_'])
                          .raises(Puppet::ExecutionFailure, 'no such role _member_')
            provider.class.expects(:openstack)
                          .with('role', 'create', '--format', 'shell', ['_member_'])
                          .returns('name="_member_"')
            provider.class.expects(:openstack)
                          .with('role', 'add', ['_member_', '--project', 'bar', '--user', 'foo'])
                          .returns('id="8wr2ff9ee4384b1894a90878d3e92bab"
name="_member_"
')
            provider.tenant=('bar')
          end
        end

# This doesn't make sense, need to clarify what's happening with LDAP mock
=begin
        context 'when using LDAP read-only backend' do
          it 'sets the tenant when _member_ role exists' do
            provider.class.expects(:openstack)
                          .with('user', 'set', [['foo', '--project', 'bar']])
                          .raises(Puppet::ExecutionFailure, 'You are not authorized to perform the requested action: LDAP user update')
            provider.class.expects(:openstack)
                           .with('user role', 'list', '--quiet', '--format', 'csv', [['foo', '--project', 'bar']])
                           .returns('')
            provider.class.expects(:openstack)
                          .with('role', 'show', '--format', 'shell', [['_member_']])
                          .returns('id="9fe2ff9ee4384b1894a90878d3e92bab"
name="_member_"
')
            provider.class.expects(:openstack)
                          .with('role', 'add', [['_member_', '--project', 'bar', '--user', 'foo']])
            provider.tenant=('bar')
          end

          it 'sets the tenant and gets an unexpected exception message' do
            provider.class.expects(:openstack)
                          .with('user', 'set', [['foo', '--project', 'bar']])
                          .raises(Puppet::ExecutionFailure, 'unknown error message')
            expect{ provider.tenant=('bar') }.to raise_error(Puppet::ExecutionFailure, /unknown error message/)
          end
        end
=end
      end
    end
  end

  describe "#password" do
    let(:user_attrs) do
      {
        :name         => 'foo',
        :ensure       => 'present',
        :enabled      => 'True',
        :password     => 'foo',
        :tenant       => 'foo',
        :email        => 'foo@example.com',
      }
    end

    let(:resource) do
      Puppet::Type::Keystone_user.new(user_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    shared_examples 'with auth-url environment variable' do
      ENV['OS_AUTH_URL'] = 'http://localhost:5000'
    end

    it_behaves_like 'with auth-url environment variable' do
      it 'checks the password' do
        Puppet::Provider::Openstack.stubs(:openstack)
                      .with('token', 'issue', ['--format', 'value'])
                      .returns('2015-05-14T04:06:05Z
e664a386befa4a30878dcef20e79f167
8dce2ae9ecd34c199d2877bf319a3d06
ac43ec53d5a74a0b9f51523ae41a29f0
')
        password = provider.password
        expect(password).to eq('foo')
      end

      it 'fails the password check' do
        Puppet::Provider::Openstack.stubs(:openstack)
                      .with('token', 'issue', ['--format', 'value'])
                      .raises(Puppet::ExecutionFailure, 'HTTP 401 invalid authentication')
        password = provider.password
        expect(password).to eq(nil)
      end
    end

    describe 'when updating a user with unmanaged password' do

      let(:user_attrs) do
        {
          :name             => 'foo',
          :ensure           => 'present',
          :enabled          => 'True',
          :password         => 'foo',
          :replace_password => 'False',
          :tenant           => 'foo',
          :email            => 'foo@example.com',
        }
      end

      it 'should not try to check password' do
        expect(provider.password).to eq('foo')
      end
    end

  end
end
