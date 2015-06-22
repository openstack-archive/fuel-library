require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_endpoint/openstack'

provider_class = Puppet::Type.type(:keystone_endpoint).provider(:openstack)

describe provider_class do

  shared_examples 'authenticated with environment variables' do
    ENV['OS_USERNAME']     = 'test'
    ENV['OS_PASSWORD']     = 'abc123'
    ENV['OS_PROJECT_NAME'] = 'test'
    ENV['OS_AUTH_URL']     = 'http://127.0.0.1:35357/v2.0'
  end

  describe 'when managing an endpoint' do

    let(:endpoint_attrs) do
      {
        :name         => 'foo/bar',
        :ensure       => 'present',
        :public_url   => 'http://127.0.0.1:5000/v2.0',
        :internal_url => 'http://127.0.0.1:5001/v2.0',
        :admin_url    => 'http://127.0.0.1:5002/v2.0',
      }
    end

    let(:resource) do
      Puppet::Type::Keystone_endpoint.new(endpoint_attrs)
    end

    let(:provider) do
      provider_class.new(resource)
    end

    it_behaves_like 'authenticated with environment variables' do
      describe '#create' do
        it 'creates an endpoint' do
          provider.class.stubs(:openstack)
                        .with('endpoint', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Region","Service Name","Service Type","PublicURL","AdminURL","InternalURL"
"1cb05cfed7c24279be884ba4f6520262","foo","bar","","http://127.0.0.1:5000/v2.0","http://127.0.0.1:5001/v2.0","http://127.0.0.1:5002/v2.0"
')
          provider.class.stubs(:openstack)
                        .with('endpoint', 'create', '--format', 'shell', ['bar', '--region', 'foo', '--publicurl', 'http://127.0.0.1:5000/v2.0', '--internalurl', 'http://127.0.0.1:5001/v2.0', '--adminurl', 'http://127.0.0.1:5002/v2.0'])
                        .returns('adminurl="http://127.0.0.1:5002/v2.0"
id="3a5c4378981e4112a0d44902a43e16ef"
internalurl="http://127.0.0.1:5001/v2.0"
publicurl="http://127.0.0.1:5000/v2.0"
region="foo"
service_id="8137d72980fd462192f276585a002426"
service_name="bar"
service_type="test"
')
          provider.create
          expect(provider.exists?).to be_truthy
        end
      end

      describe '#destroy' do
        it 'destroys an endpoint' do
          provider.class.stubs(:openstack)
                        .with('endpoint', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Region","Service Name","Service Type","PublicURL","AdminURL","InternalURL"
"1cb05cfed7c24279be884ba4f6520262","foo","bar","test","http://127.0.0.1:5000/v2.0","http://127.0.0.1:5001/v2.0","http://127.0.0.1:5002/v2.0"
')
          provider.class.stubs(:openstack)
                        .with('endpoint', 'delete', [])
          provider.destroy
          expect(provider.exists?).to be_falsey
        end
      end

      describe '#exists' do
        context 'when tenant does not exist' do
          subject(:response) do
            provider.class.stubs(:openstack)
                          .with('endpoint', 'list', '--quiet', '--format', 'csv', '--long')
                          .returns('"ID","Region","Service Name","Service Type","PublicURL","AdminURL","InternalURL"')
            response = provider.exists?
          end

          it { is_expected.to be_falsey }
        end
      end

      describe '#instances' do
        it 'finds every tenant' do
          provider.class.stubs(:openstack)
                        .with('endpoint', 'list', '--quiet', '--format', 'csv', '--long')
                        .returns('"ID","Region","Service Name","Service Type","PublicURL","AdminURL","InternalURL"
"3a5c4378981e4112a0d44902a43e16ef","foo","bar","test","http://127.0.0.1:5000/v2.0","http://127.0.0.1:5001/v2.0","http://127.0.0.1:5002/v2.0"
')
          instances = Puppet::Type::Keystone_endpoint::ProviderOpenstack.instances
          expect(instances.count).to eq(1)
        end
      end
    end
  end
end
