require 'puppet'
require 'mocha'
require 'spec_helper'
RSpec.configure do |config|
  config.mock_with :mocha
end
class Connection
  def initialize(node)
    @node = node
    @registered = false
  end
  def get(url,headers)
    if url == '/ws.v1/transport-node'
      return '','{"results": [{"_href": "/ws.v1/transport-node/550e8400-e29b-41d4-a716-446655440001"}]}'
    else
      return '',"{\"display_name\": \"#{@node}\", \"uuid\":\"550e8400-e29b-41d4-a716-446655440001\"}"
    end
  end
  def registered
    @registered
  end
  def post(*args)
    @registered = true
  end
end
provider_class = Puppet::Type.type(:l2_ovs_nsx).provider(:ovs)
describe provider_class do
  before :each do
    @res = Puppet::Type::L2_ovs_nsx.new(
      {:nsx_username => 'admin',
      :nsx_password => 'admin',
      :nsx_endpoint => '10.30.0.100,10.30.0.101,10.30.0.102',
      :display_name => 'node-10',
      :transport_zone_uuid => '550e8400-e29b-41d4-a716-446655440000',
      :ip_address => '10.30.0.10',
      :connector_type => 'stt',
      :integration_bridge => 'br-int',}
    )
    @provider = provider_class.new(@res)
    @conn = Connection.new('node-10')
    @provider.stubs(:login).returns(@conn)
    @provider.exists?
    File.stubs(:exists?).returns(true)
    provider_class.stubs(:vspki).returns("")
    provider_class.stubs(:vsctl).returns("")
  end
  it "should return uuid" do
    @provider.get_uuid.should == "550e8400-e29b-41d4-a716-446655440001"
  end
  it "shold register node" do
    @provider.stubs(:get_cert).returns("")
    @provider.create
    @conn.registered.should == true
  end
end

