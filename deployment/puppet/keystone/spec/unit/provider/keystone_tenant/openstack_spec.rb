require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_tenant/openstack'

provider_class = Puppet::Type.type(:keystone_tenant).provider(:openstack)

describe provider_class do

  shared_examples 'authenticated with environment variables' do
    ENV['OS_USERNAME']     = 'test'
    ENV['OS_PASSWORD']     = 'abc123'
    ENV['OS_PROJECT_NAME'] = 'test'
    ENV['OS_AUTH_URL']     = 'http://127.0.0.1:35357/v2.0'
  end

  describe 'when managing a tenant' do

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

    it_behaves_like 'authenticated with environment variables' do
      describe '#create' do
        it 'creates a tenant' do
          provider.class.stubs(:openstack)
                        .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo",True
')
          provider.class.stubs(:openstack)
                        .with('project', 'create', '--format', 'shell', ['foo', '--enable', '--description', 'foo'])
                        .returns('description="foo"
enabled="True"
name="foo"
')
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy' do
        it 'destroys a tenant' do
          provider.class.stubs(:openstack)
                        .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Description","Enabled"')
          provider.class.stubs(:openstack)
                        .with('project', 'delete', [])
          provider.destroy
          expect(provider.exists?).to be_falsey
        end
      end

      context 'when tenant does not exist' do
        subject(:response) do
          provider.class.stubs(:openstack)
                        .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Description","Enabled"')
          response = provider.exists?
        end

        it { is_expected.to be_falsey }
      end

      describe '#instances' do
        it 'finds every tenant' do
          provider.class.stubs(:openstack)
                        .with('project', 'list', '--quiet', '--format', 'csv', '--long')
                       .returns('"ID","Name","Description","Enabled"
"1cb05cfed7c24279be884ba4f6520262","foo","foo",True
')
          instances = Puppet::Type::Keystone_tenant::ProviderOpenstack.instances
          expect(instances.count).to eq(1)
        end
      end
    end
  end
end
