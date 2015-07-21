require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_user/openstack'
require 'puppet/provider/openstack'

provider_class = Puppet::Type.type(:keystone_user).provider(:openstack)

def project_class
  Puppet::Type.type(:keystone_tenant).provider(:openstack)
end

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
      :domain       => 'foo_domain',
    }
  end

  let(:resource) do
    Puppet::Type::Keystone_user.new(user_attrs)
  end

  let(:provider) do
    provider_class.new(resource)
  end

  def before_hook(delete, missing, noproject, user_cached)
    provider.class.expects(:openstack).once
                  .with('domain', 'list', '--quiet', '--format', 'csv', [])
                  .returns('"ID","Name","Enabled","Description"
"foo_domain_id","foo_domain",True,"foo domain"
"bar_domain_id","bar_domain",True,"bar domain"
"another_domain_id","another_domain",True,"another domain"
"disabled_domain_id","disabled_domain",False,"disabled domain"
')
    if user_cached
      return # using cached user, so no user list
    end
    if noproject
      project = ''
    else
      project = 'foo'
    end
    # delete will call the search again and should not return the deleted user
    foo_returns = ['"ID","Name","Project Id","Domain","Description","Email","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo",' + project + ',"foo_domain_id","foo description","foo@example.com",True
"2cb05cfed7c24279be884ba4f6520262","foo",' + project + ',"bar_domain_id","foo description","foo@example.com",True
"3cb05cfed7c24279be884ba4f6520262","foo",' + project + ',"another_domain_id","foo description","foo@example.com",True
']
    nn = 1
    if delete
      nn = 2
      foo_returns << ''
    end
    if missing
      foo_returns = ['']
    end
    provider.class.expects(:openstack).times(nn)
                  .with('user', 'list', '--quiet', '--format', 'csv', ['--long'])
                  .returns(*foo_returns)
  end

  before :each, :default => true do
    before_hook(false, false, false, false)
  end
  before :each, :delete => true do
    before_hook(true, false, false, false)
  end
  before :each, :missing => true do
    before_hook(false, true, false, false)
  end
  before :each, :noproject => true do
    before_hook(false, false, true, false)
  end
  before :each, :default_https => true do
    before_hook(false, false, false, false)
  end
  before :each, :user_cached => true do
    before_hook(false, false, false, true)
  end
  before :each, :nohooks => true do
    # do nothing
  end

  describe 'when managing a user' do
    it_behaves_like 'authenticated with environment variables' do
      describe '#create' do
        it 'creates a user' do
          project_class.expects(:openstack).once
                       .with('domain', 'list', '--quiet', '--format', 'csv', [])
                       .returns('"ID","Name","Enabled","Description"
"foo_domain_id","foo_domain",True,"foo domain"
"bar_domain_id","bar_domain",True,"bar domain"
"another_domain_id","another_domain",True,"another domain"
"disabled_domain_id","disabled_domain",False,"disabled domain"
')
          project_class.expects(:openstack)
                       .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                       .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","foo","bar_domain_id","foo",True
')
          provider.class.expects(:openstack)
                        .with('role', 'show', '--format', 'shell', '_member_')
                        .returns('
name="_member_"
')
          provider.class.expects(:openstack)
                        .with('role', 'add', ['_member_', '--project', '2cb05cfed7c24279be884ba4f6520262', '--user', '12b23f07d4a3448d8189521ab09610b0'])
          provider.class.expects(:openstack)
                        .with('user', 'create', '--format', 'shell', ['foo', '--enable', '--password', 'foo', '--email', 'foo@example.com', '--domain', 'foo_domain'])
                        .returns('email="foo@example.com"
enabled="True"
id="12b23f07d4a3448d8189521ab09610b0"
name="foo"
username="foo"
')
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy' do
        it 'destroys a user' do
          provider.instance_variable_get('@property_hash')[:id] = 'my-user-id'
          provider.class.expects(:openstack)
                        .with('user', 'delete', 'my-user-id')
          provider.destroy
          expect(provider.exists?).to be_falsey
        end

      end

      describe '#exists' do
        context 'when user does not exist' do
          subject(:response) do
            response = provider.exists?
          end

          it { is_expected.to be_falsey }
        end
      end

      describe '#instances', :default => true do
        it 'finds every user' do
          instances = provider.class.instances
          expect(instances.count).to eq(3)
          expect(instances[0].name).to eq('foo')
          expect(instances[0].domain).to eq('another_domain')
          expect(instances[1].name).to eq('foo::foo_domain')
          expect(instances[2].name).to eq('foo::bar_domain')
        end
      end

      describe '#tenant' do
        it 'gets the tenant with default backend', :nohooks => true do
            project_class.expects(:openstack)
                         .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                         .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
          provider.class.expects(:openstack)
                        .with('project', 'list', '--quiet', '--format', 'csv', ['--user', '1cb05cfed7c24279be884ba4f6520262', '--long'])
                        .returns('"ID","Name","Domain ID","Description","Enabled"
"foo_project_id1","foo","foo_domain_id","",True
')
          provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
          tenant = provider.tenant
          expect(tenant).to eq('foo')
        end

        it 'gets the tenant with LDAP backend', :nohooks => true do
          provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
            project_class.expects(:openstack)
                         .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                         .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
          provider.class.expects(:openstack)
                        .with('project', 'list', '--quiet', '--format', 'csv', ['--user', '1cb05cfed7c24279be884ba4f6520262', '--long'])
                        .returns('"ID","Name","Domain ID","Description","Enabled"
"foo_project_id1","foo","foo_domain_id","",True
"bar_project_id2","bar","bar_domain_id","",True
"foo_project_id2","foo","another_domain_id","",True
')
          tenant = provider.tenant
          expect(tenant).to eq('foo')
        end
      end
      describe '#tenant=' do
        context 'when using default backend', :nohooks => true do
          it 'sets the tenant' do
            provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
            provider.instance_variable_get('@property_hash')[:domain] = 'foo_domain'
            project_class.expects(:openstack)
                         .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                         .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
            provider.class.expects(:openstack)
                          .with('role', 'show', '--format', 'shell', '_member_')
                          .returns('name="_member_"')
            provider.class.expects(:openstack)
                          .with('role', 'add', ['_member_', '--project', '2cb05cfed7c24279be884ba4f6520262', '--user', '1cb05cfed7c24279be884ba4f6520262'])
            provider.tenant=('bar')
          end
        end
        context 'when using LDAP read-write backend', :nohooks => true do
          it 'sets the tenant when _member_ role exists' do
            provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
            provider.instance_variable_get('@property_hash')[:domain] = 'foo_domain'
            project_class.expects(:openstack)
                         .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                         .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
            provider.class.expects(:openstack)
                          .with('role', 'show', '--format', 'shell', '_member_')
                          .returns('name="_member_"')
            provider.class.expects(:openstack)
                          .with('role', 'add', ['_member_', '--project', '2cb05cfed7c24279be884ba4f6520262', '--user', '1cb05cfed7c24279be884ba4f6520262'])
            provider.tenant=('bar')
          end
          it 'sets the tenant when _member_ role does not exist' do
            provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
            provider.instance_variable_get('@property_hash')[:domain] = 'foo_domain'
            project_class.expects(:openstack)
                         .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                         .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
            provider.class.expects(:openstack)
                          .with('role', 'show', '--format', 'shell', '_member_')
                          .raises(Puppet::ExecutionFailure, 'no such role _member_')
            provider.class.expects(:openstack)
                          .with('role', 'create', '--format', 'shell', '_member_')
                          .returns('name="_member_"')
            provider.class.expects(:openstack)
                          .with('role', 'add', ['_member_', '--project', '2cb05cfed7c24279be884ba4f6520262', '--user', '1cb05cfed7c24279be884ba4f6520262'])
            provider.tenant=('bar')
          end
        end
        context 'when using LDAP read-only backend', :nohooks => true do
          it 'sets the tenant when _member_ role exists' do
            provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
            provider.instance_variable_get('@property_hash')[:domain] = 'foo_domain'
            project_class.expects(:openstack)
                         .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                         .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
            provider.class.expects(:openstack)
                          .with('role', 'show', '--format', 'shell', '_member_')
                          .returns('name="_member_"')
            provider.class.expects(:openstack)
                          .with('role', 'add', ['_member_', '--project', '2cb05cfed7c24279be884ba4f6520262', '--user', '1cb05cfed7c24279be884ba4f6520262'])
            provider.tenant=('bar')
          end
        end
      end
    end
  end

  describe "#password", :nohooks => true do
    let(:user_attrs) do
      {
        :name         => 'foo',
        :ensure       => 'present',
        :enabled      => 'True',
        :password     => 'foo',
        :tenant       => 'foo',
        :email        => 'foo@example.com',
        :domain       => 'foo_domain',
      }
    end

    let(:resource) do
      Puppet::Type::Keystone_user.new(user_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    shared_examples 'with auth-url environment variable' do
      ENV['OS_AUTH_URL'] = 'http://127.0.0.1:5000'
    end

    it_behaves_like 'with auth-url environment variable' do
      it 'checks the password' do
        provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
        mockcreds = {}
        Puppet::Provider::Openstack::CredentialsV3.expects(:new).returns(mockcreds)
        mockcreds.expects(:auth_url=).with('http://127.0.0.1:5000')
        mockcreds.expects(:password=).with('foo')
        mockcreds.expects(:username=).with('foo')
        mockcreds.expects(:user_id=).with('1cb05cfed7c24279be884ba4f6520262')
        mockcreds.expects(:project_id=).with('project-id-1')
        mockcreds.expects(:to_env).returns(mockcreds)
        Puppet::Provider::Openstack.expects(:openstack)
                      .with('project', 'list', '--quiet', '--format', 'csv', ['--user', '1cb05cfed7c24279be884ba4f6520262', '--long'])
                      .returns('"ID","Name","Domain ID","Description","Enabled"
"project-id-1","foo","foo_domain_id","foo",True
')
        Puppet::Provider::Openstack.expects(:openstack)
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
        provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
        Puppet::Provider::Openstack.expects(:openstack)
                      .with('project', 'list', '--quiet', '--format', 'csv', ['--user', '1cb05cfed7c24279be884ba4f6520262', '--long'])
                      .returns('"ID","Name","Domain ID","Description","Enabled"
"project-id-1","foo","foo_domain_id","foo",True
')
        Puppet::Provider::Openstack.expects(:openstack)
                      .with('token', 'issue', ['--format', 'value'])
                      .raises(Puppet::ExecutionFailure, 'HTTP 401 invalid authentication')
        password = provider.password
        expect(password).to eq(nil)
      end

      it 'checks the password with domain scoped token' do
        provider.instance_variable_get('@property_hash')[:id] = '1cb05cfed7c24279be884ba4f6520262'
        provider.instance_variable_get('@property_hash')[:domain] = 'foo_domain'
        mockcreds = {}
        Puppet::Provider::Openstack::CredentialsV3.expects(:new).returns(mockcreds)
        mockcreds.expects(:auth_url=).with('http://127.0.0.1:5000')
        mockcreds.expects(:password=).with('foo')
        mockcreds.expects(:username=).with('foo')
        mockcreds.expects(:user_id=).with('1cb05cfed7c24279be884ba4f6520262')
        mockcreds.expects(:domain_name=).with('foo_domain')
        mockcreds.expects(:to_env).returns(mockcreds)
        Puppet::Provider::Openstack.expects(:openstack)
                      .with('project', 'list', '--quiet', '--format', 'csv', ['--user', '1cb05cfed7c24279be884ba4f6520262', '--long'])
                      .returns('"ID","Name","Domain ID","Description","Enabled"
')
        Puppet::Provider::Openstack.expects(:openstack)
                      .with('token', 'issue', ['--format', 'value'])
                      .returns('2015-05-14T04:06:05Z
e664a386befa4a30878dcef20e79f167
8dce2ae9ecd34c199d2877bf319a3d06
ac43ec53d5a74a0b9f51523ae41a29f0
')
        password = provider.password
        expect(password).to eq('foo')
      end
    end
  end

  describe 'when updating a user with unmanaged password', :nohooks => true do

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
          :domain           => 'foo_domain',
        }
      end

      let(:resource) do
        Puppet::Type::Keystone_user.new(user_attrs)
      end

      let :provider do
        provider_class.new(resource)
      end

      it 'should not try to check password' do
        expect(provider.password).to eq('foo')
      end
    end
  end

  it_behaves_like 'authenticated with environment variables' do
    describe 'v3 domains with no domain in resource', :nohooks => true do
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

      it 'adds default domain to commands' do
        provider_class.class_exec {
          @default_domain_id = nil
        }
        mock = {
          'identity' => {'default_domain_id' => 'foo_domain_id'}
        }
        Puppet::Util::IniConfig::File.expects(:new).returns(mock)
        File.expects(:exists?).with('/etc/keystone/keystone.conf').returns(true)
        mock.expects(:read).with('/etc/keystone/keystone.conf')
        provider.class.expects(:openstack)
                     .with('project', 'list', '--quiet', '--format', 'csv', ['--user', '1cb05cfed7c24279be884ba4f6520262', '--long'])
                     .returns('"ID","Name"
')
        project_class.expects(:openstack)
                     .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                     .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
        provider.class.expects(:openstack)
                      .with('role', 'show', '--format', 'shell', '_member_')
                      .returns('
name="_member_"
')
        provider.class.expects(:openstack)
                      .with('role', 'add', ['_member_', '--project', '1cb05cfed7c24279be884ba4f6520262', '--user', '1cb05cfed7c24279be884ba4f6520262'])
        provider.class.expects(:openstack)
                      .with('user', 'create', '--format', 'shell', ['foo', '--enable', '--password', 'foo', '--email', 'foo@example.com', '--domain', 'foo_domain'])
                    .returns('email="foo@example.com"
enabled="True"
id="1cb05cfed7c24279be884ba4f6520262"
name="foo"
username="foo"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("1cb05cfed7c24279be884ba4f6520262")
      end
    end

    describe 'v3 domains with domain in resource' do
      let(:user_attrs) do
        {
          :name         => 'foo',
          :ensure       => 'present',
          :enabled      => 'True',
          :password     => 'foo',
          :tenant       => 'foo',
          :email        => 'foo@example.com',
          :domain       => 'bar_domain',
        }
      end

      it 'uses given domain in commands' do
        project_class.expects(:openstack)
                     .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                     .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
        provider.class.expects(:openstack)
                      .with('role', 'show', '--format', 'shell', '_member_')
                      .returns('
name="_member_"
')
        provider.class.expects(:openstack)
                      .with('role', 'add', ['_member_', '--project', '1cb05cfed7c24279be884ba4f6520262', '--user', '2cb05cfed7c24279be884ba4f6520262'])
        provider.class.expects(:openstack)
                      .with('user', 'create', '--format', 'shell', ['foo', '--enable', '--password', 'foo', '--email', 'foo@example.com', '--domain', 'bar_domain'])
                      .returns('email="foo@example.com"
enabled="True"
id="2cb05cfed7c24279be884ba4f6520262"
name="foo"
username="foo"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("2cb05cfed7c24279be884ba4f6520262")
      end
    end

    describe 'v3 domains with domain in name/title' do
      let(:user_attrs) do
        {
          :name         => 'foo::bar_domain',
          :ensure       => 'present',
          :enabled      => 'True',
          :password     => 'foo',
          :tenant       => 'foo',
          :email        => 'foo@example.com',
        }
      end

      it 'uses given domain in commands' do
        project_class.expects(:openstack)
                     .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                     .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
        provider.class.expects(:openstack)
                      .with('role', 'show', '--format', 'shell', '_member_')
                      .returns('
name="_member_"
')
        provider.class.expects(:openstack)
                      .with('role', 'add', ['_member_', '--project', '1cb05cfed7c24279be884ba4f6520262', '--user', '2cb05cfed7c24279be884ba4f6520262'])
        provider.class.expects(:openstack)
                      .with('user', 'create', '--format', 'shell', ['foo', '--enable', '--password', 'foo', '--email', 'foo@example.com', '--domain', 'bar_domain'])
                      .returns('email="foo@example.com"
enabled="True"
id="2cb05cfed7c24279be884ba4f6520262"
name="foo"
username="foo"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("2cb05cfed7c24279be884ba4f6520262")
      end
    end

    describe 'v3 domains with domain in name/title and in resource' do
      let(:user_attrs) do
        {
          :name         => 'foo::bar_domain',
          :ensure       => 'present',
          :enabled      => 'True',
          :password     => 'foo',
          :tenant       => 'foo',
          :email        => 'foo@example.com',
          :domain       => 'foo_domain',
        }
      end

      it 'uses the resource domain in commands' do
        project_class.expects(:openstack)
                     .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                     .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","bar","bar_domain_id","bar",True
')
        provider.class.expects(:openstack)
                      .with('role', 'show', '--format', 'shell', '_member_')
                      .returns('
name="_member_"
')
        provider.class.expects(:openstack)
                      .with('role', 'add', ['_member_', '--project', '1cb05cfed7c24279be884ba4f6520262', '--user', '2cb05cfed7c24279be884ba4f6520262'])
        provider.class.expects(:openstack)
                      .with('user', 'create', '--format', 'shell', ['foo', '--enable', '--password', 'foo', '--email', 'foo@example.com', '--domain', 'foo_domain'])
                      .returns('email="foo@example.com"
enabled="True"
id="2cb05cfed7c24279be884ba4f6520262"
name="foo"
username="foo"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("2cb05cfed7c24279be884ba4f6520262")
      end
    end

    describe 'v3 domains with domain in name/title and in resource and in tenant' do
      let(:user_attrs) do
        {
          :name         => 'foo::bar_domain',
          :ensure       => 'present',
          :enabled      => 'True',
          :password     => 'foo',
          :tenant       => 'foo::foo_domain',
          :email        => 'foo@example.com',
          :domain       => 'foo_domain',
        }
      end

      it 'uses the resource domain in commands' do
        project_class.expects(:openstack)
                     .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                     .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","foo","bar_domain_id","foo",True
')
        provider.class.expects(:openstack)
                      .with('role', 'show', '--format', 'shell', '_member_')
                      .returns('
name="_member_"
')
        provider.class.expects(:openstack)
                      .with('role', 'add', ['_member_', '--project', '1cb05cfed7c24279be884ba4f6520262', '--user', '2cb05cfed7c24279be884ba4f6520262'])
        provider.class.expects(:openstack)
                      .with('user', 'create', '--format', 'shell', ['foo', '--enable', '--password', 'foo', '--email', 'foo@example.com', '--domain', 'foo_domain'])
                      .returns('email="foo@example.com"
enabled="True"
id="2cb05cfed7c24279be884ba4f6520262"
name="foo"
username="foo"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("2cb05cfed7c24279be884ba4f6520262")
      end
    end
  end
end
