require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_tenant/openstack'

provider_class = Puppet::Type.type(:keystone_tenant).provider(:openstack)

class Puppet::Provider::Keystone
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

describe provider_class do

  after :each do
    provider_class.reset
  end

  let(:tenant_attrs) do
    {
      :name         => 'foo',
      :description  => 'foo',
      :ensure       => 'present',
      :enabled      => 'True',
    }
  end

  let(:resource) do
    Puppet::Type::Keystone_tenant.new(tenant_attrs)
  end

  let(:provider) do
    provider_class.new(resource)
  end

  def before_hook(domainlist)
    if domainlist
      provider.class.expects(:openstack).once
                    .with('domain', 'list', '--quiet', '--format', 'csv', [])
                    .returns('"ID","Name","Enabled","Description"
"foo_domain_id","foo_domain",True,"foo domain"
"bar_domain_id","bar_domain",True,"bar domain"
"another_domain_id","another_domain",True,"another domain"
"disabled_domain_id","disabled_domain",False,"disabled domain"
"default","Default",True,"the default domain"
')
    end
  end

  before :each, :domainlist => true do
    before_hook(true)
  end

  before :each, :domainlist => false do
    before_hook(false)
  end

  shared_examples 'authenticated with environment variables' do
    ENV['OS_USERNAME']     = 'test'
    ENV['OS_PASSWORD']     = 'abc123'
    ENV['OS_PROJECT_NAME'] = 'test'
    ENV['OS_AUTH_URL']     = 'http://127.0.0.1:35357/v3'
  end

  describe 'when managing a tenant' do

    it_behaves_like 'authenticated with environment variables' do
      describe '#create', :domainlist => true do
        it 'creates a tenant' do
          provider.class.expects(:openstack)
                        .with('project', 'create', '--format', 'shell', ['foo', '--enable', '--description', 'foo', '--domain', 'Default'])
                        .returns('description="foo"
enabled="True"
name="foo"
id="foo"
domain_id="foo_domain_id"
')
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy', :domainlist => false do
        it 'destroys a tenant' do
          provider.instance_variable_get('@property_hash')[:id] = 'my-project-id'
          provider.class.expects(:openstack)
                        .with('project', 'delete', 'my-project-id')
          provider.destroy
          expect(provider.exists?).to be_falsey
        end
      end

      context 'when tenant does not exist', :domainlist => false do
        subject(:response) do
          response = provider.exists?
        end

        it { expect(response).to be_falsey }
      end

      describe '#instances', :domainlist => true do
        it 'finds every tenant' do
          provider.class.expects(:openstack)
                        .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                       .returns('"ID","Name","Domain ID","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo_domain_id","foo",True
"2cb05cfed7c24279be884ba4f6520262","foo","bar_domain_id","foo",True
')
          instances = provider.class.instances
          expect(instances[0].name).to eq('foo')
          expect(instances[0].domain).to eq('bar_domain')
          expect(instances[1].name).to eq('foo::foo_domain')
        end
      end
    end

    describe 'v3 domains with no domain in resource', :domainlist => true do

      let(:tenant_attrs) do
        {
          :name         => 'foo',
          :description  => 'foo',
          :ensure       => 'present',
          :enabled      => 'True'
        }
      end

      it 'adds default domain to commands' do
        mock = {
          'identity' => {'default_domain_id' => 'foo_domain_id'}
        }
        Puppet::Util::IniConfig::File.expects(:new).returns(mock)
        File.expects(:exists?).with('/etc/keystone/keystone.conf').returns(true)
        mock.expects(:read).with('/etc/keystone/keystone.conf')
        provider.class.expects(:openstack)
          .with('project', 'create', '--format', 'shell', ['foo', '--enable', '--description', 'foo', '--domain', 'foo_domain'])
          .returns('description="foo"
enabled="True"
name="foo"
id="project-id"
domain_id="foo_domain_id"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("project-id")
      end

    end

    describe 'v3 domains with domain in resource', :domainlist => false do

      let(:tenant_attrs) do
        {
          :name         => 'foo',
          :description  => 'foo',
          :ensure       => 'present',
          :enabled      => 'True',
          :domain       => 'foo_domain'
        }
      end

      it 'uses given domain in commands' do
        provider.class.expects(:openstack)
          .with('project', 'create', '--format', 'shell', ['foo', '--enable', '--description', 'foo', '--domain', 'foo_domain'])
          .returns('description="foo"
enabled="True"
name="foo"
id="project-id"
domain_id="foo_domain_id"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("project-id")
      end
    end

    describe 'v3 domains with domain in name/title', :domainlist => false do

      let(:tenant_attrs) do
        {
          :name         => 'foo::foo_domain',
          :description  => 'foo',
          :ensure       => 'present',
          :enabled      => 'True'
        }
      end

      it 'uses given domain in commands' do
        provider.class.expects(:openstack)
          .with('project', 'create', '--format', 'shell', ['foo', '--enable', '--description', 'foo', '--domain', 'foo_domain'])
          .returns('description="foo"
enabled="True"
name="foo"
id="project-id"
domain_id="foo_domain_id"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("project-id")
      end
    end

    describe 'v3 domains with domain in name/title and in resource', :domainlist => false do

      let(:tenant_attrs) do
        {
          :name         => 'foo::bar_domain',
          :description  => 'foo',
          :ensure       => 'present',
          :enabled      => 'True',
          :domain       => 'foo_domain'
        }
      end

      it 'uses given domain in commands' do
        provider.class.expects(:openstack)
          .with('project', 'create', '--format', 'shell', ['foo', '--enable', '--description', 'foo', '--domain', 'foo_domain'])
          .returns('description="foo"
enabled="True"
name="foo"
id="project-id"
domain_id="foo_domain_id"
')
        provider.create
        expect(provider.exists?).to be_truthy
        expect(provider.id).to eq("project-id")
      end
    end
  end
end
