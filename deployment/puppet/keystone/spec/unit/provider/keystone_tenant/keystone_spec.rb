require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_tenant/keystone'

provider_class = Puppet::Type.type(:keystone_tenant).provider(:keystone)

describe provider_class do

  describe 'when updating a tenant' do

    let :tenant_name do
      'foo'
    end

    let :tenant_attrs do
      {
        :name         => tenant_name,
        :description  => '',
        :ensure       => 'present',
        :enabled      => 'True',
      }
    end

    let :tenant_hash do
      { tenant_name => {
          :id           => 'id',
          :name         => tenant_name,
          :description  => '',
          :ensure       => 'present',
          :enabled      => 'True',
        }
      }
    end

    let :resource do
      Puppet::Type::Keystone_tenant.new(tenant_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    before :each do
      provider_class.expects(:build_tenant_hash).returns(tenant_hash)
    end

    it 'should call tenant-update to set enabled' do
      provider.expects(:auth_keystone).with('tenant-update',
                                            '--enabled',
                                            'False',
                                            'id')
      provider.enabled=('False')
    end
  end
end
