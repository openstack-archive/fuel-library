require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_service/openstack'

provider_class = Puppet::Type.type(:keystone_service).provider(:openstack)

describe provider_class do

  shared_examples 'authenticated with environment variables' do
    ENV['OS_USERNAME']     = 'test'
    ENV['OS_PASSWORD']     = 'abc123'
    ENV['OS_PROJECT_NAME'] = 'test'
    ENV['OS_AUTH_URL']     = 'http://127.0.0.1:5000/v3'
  end

  describe 'when managing a service' do

    let(:service_attrs) do
      {
        :name         => 'foo',
        :description  => 'foo',
        :ensure       => 'present',
        :type         => 'foo',
      }
    end

    let(:resource) do
      Puppet::Type::Keystone_service.new(service_attrs)
    end

    let(:provider) do
      provider_class.new(resource)
    end

    it_behaves_like 'authenticated with environment variables' do
      describe '#create' do
        it 'creates a service' do
          provider.class.stubs(:openstack)
                        .with('service', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Type","Description"
"1cb05cfed7c24279be884ba4f6520262","foo","foo","foo"
')
          provider.class.stubs(:openstack)
                        .with('service', 'create', '--format', 'shell', ['foo', '--name', 'foo', '--description', 'foo'])
                        .returns('description="foo"
enabled="True"
id="8f0dd4c0abc44240998fbb3f5089ecbf"
name="foo"
type="foo"
')
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy' do
        it 'destroys a service' do
          provider.class.stubs(:openstack)
                        .with('service', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Type","Description"
"1cb05cfed7c24279be884ba4f6520262","foo","foo","foo"
')
          provider.class.stubs(:openstack)
                        .with('service', 'delete', [])
          provider.destroy
          expect(provider.exists?).to be_falsey
        end

        context 'when service does not exist' do
          subject(:response) do
            provider.class.stubs(:openstack)
                          .with('service', 'list', '--quiet', '--format', 'csv', '--long')
                          .returns('"ID","Name","Type","Description"')
            response = provider.exists?
          end
          it { is_expected.to be_falsey }
        end
      end

      describe '#instances' do
        it 'finds every service' do
          provider.class.stubs(:openstack)
                        .with('service', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Name","Type","Description"
"8f0dd4c0abc44240998fbb3f5089ecbf","foo","foo","foo"
')
          instances = Puppet::Type::Keystone_service::ProviderOpenstack.instances
          expect(instances.count).to eq(1)
        end
      end
    end
  end
end
