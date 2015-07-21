require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_role/openstack'

provider_class = Puppet::Type.type(:keystone_role).provider(:openstack)

describe provider_class do

  shared_examples 'authenticated with environment variables' do
    ENV['OS_USERNAME']     = 'test'
    ENV['OS_PASSWORD']     = 'abc123'
    ENV['OS_PROJECT_NAME'] = 'test'
    ENV['OS_AUTH_URL']     = 'http://127.0.0.1:5000'
  end

  describe 'when creating a role' do
    it_behaves_like 'authenticated with environment variables' do
      let(:role_attrs) do
        {
          :name         => 'foo',
          :ensure       => 'present',
        }
      end

      let(:resource) do
        Puppet::Type::Keystone_role.new(role_attrs)
      end

      let(:provider) do
        provider_class.new(resource)
      end

      describe '#create' do
        it 'creates a role' do
          provider.class.expects(:openstack)
                        .with('role', 'create', '--format', 'shell', 'foo')
                        .returns('name="foo"')
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy' do
        it 'destroys a role' do
          provider.class.expects(:openstack)
                        .with('role', 'delete', [])
          provider.destroy
          expect(provider.exists?).to be_falsey
        end

      end

      describe '#exists' do
        context 'when role does not exist' do
          subject(:response) do
            response = provider.exists?
          end
          it { is_expected.to be_falsey }
        end
      end

      describe '#instances' do
        it 'finds every role' do
          provider.class.expects(:openstack)
                        .with('role', 'list', '--quiet', '--format', 'csv', [])
                        .returns('"ID","Name"
"1cb05cfed7c24279be884ba4f6520262","foo"
')
          instances = Puppet::Type::Keystone_role::ProviderOpenstack.instances
          expect(instances.count).to eq(1)
        end
      end
    end
  end
end
