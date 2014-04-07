require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_endpoint/keystone'


describe Puppet::Type.type(:keystone_endpoint).provider(:keystone) do

  let :resource do
    Puppet::Type::Keystone_endpoint.new(
      :provider     => :keystone,
      :name         => 'region/foo',
      :ensure       => :present,
      :public_url   => 'public_url',
      :internal_url => 'internal_url',
      :admin_url    => 'admin_url'
    )
  end

  let :provider do
    described_class.new(resource)
  end

  before :each do
    # keystone endpoint-list
    described_class.stubs(:list_keystone_objects).with('endpoint', [5,6]).returns([
      ['endpoint-id', 'region', 'public_url', 'internal_url', 'admin_url', 4]
    ])
    # keystone service-list
    described_class.stubs(:list_keystone_objects).with('service', 4).returns([
      [4, 'foo', 'type', 'description']
    ])
    described_class.stubs(:get_keystone_object).with('service', 4, 'name').returns('foo')
    described_class.prefetch('region/foo' => resource)
  end

  after :each do
    described_class.prefetch({})
  end

  describe "self.instances" do
    it "should have an instances method" do
      provider.class.should respond_to(:instances)
    end

    it "should list instances" do
      endpoints = described_class.instances
      endpoints.size.should == 1
      endpoints.map {|provider| provider.name} == ['region/foo']
    end
  end

  describe '#create' do
    it 'should call endpoint-create' do
      provider.expects(:auth_keystone).with(
        'endpoint-create', '--service-id', 4, includes(
          '--publicurl', 'public_url', '--internalurl', 'internal_url',
          '--region', 'region')
      )
      provider.create
    end
  end

  describe '#flush' do
    it 'should delete and create the endpoint once when any url gets updated' do
      provider.expects(:destroy).times(1)
      provider.expects(:create).times(1)

      provider.public_url=('new-public_url')
      provider.internal_url=('new-internal_url')
      provider.admin_url=('new-admin_url')
      provider.flush
    end
  end
end
