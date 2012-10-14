require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_endpoint/keystone'

provider_class = Puppet::Type.type(:keystone_endpoint).provider(:keystone)

describe provider_class do

  describe 'when updating the endpoint URLS' do
    let :resource do
      Puppet::Type::Keystone_endpoint.new(
        {
          :name         => 'foo',
          :public_url   => 'public_url',
          :internal_url => 'internal_url',
          :admin_url    => 'admin_url'
        }
      )
    end
    let :provider do
      provider_class.new(resource)
    end
    before :each do
      provider_class.expects(:build_endpoint_hash).returns(
        'foo' => {:id   => 'id'}
      )
    end
    after :each do
      # reset global state
      provider_class.prefetch(nil)
    end
    it 'should delete endpoint for every url that gets synced' do
      provider.expects(:create).times(3)
      provider.expects(:auth_keystone).with('endpoint-delete', 'id').times(3)
      provider.public_url=('public_url')
      provider.internal_url=('internal_url')
      provider.admin_url=('admin_url')
    end
    it 'should recreate endpoints for every url that gets synced' do
      provider_class.expects(:list_keystone_objects).with('service', 4).times(3).returns(
        [['id', 'foo']]
      )
      provider.expects(:destroy).times(3)
      provider.expects(:auth_keystone).with do |a,b,c,d|
        (
          a == 'endpoint-create' &&
          b == '--service-id'       &&
          c == 'id'              &&
          d[d.index('--publicurl')   + 1 ] == 'public_url'   &&
          d[d.index('--adminurl')    + 1 ] ==  'admin_url'   &&
          d[d.index('--internalurl') + 1 ] == 'internal_url'
        )
      end.times(3)

      provider.public_url=('public_url')
      provider.internal_url=('internal_url')
      provider.admin_url=('admin_url')
    end
  end
end
