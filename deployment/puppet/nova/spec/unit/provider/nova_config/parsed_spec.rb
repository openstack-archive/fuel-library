require 'puppet'
require 'mocha'
require 'tempfile'
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Type.type(:nova_config).provider(:parsed)
describe provider_class do
  before :each do
    @nova_config = Tempfile.new('nova.conf')
    @resource = Puppet::Type::Nova_config.new(
      {:target => @nova_config, :name => 'foo', :value => 'bar'}
    )
    @provider = provider_class.new(@resource)
  end
  it 'should be able to parse lines into records' do
    record = @provider.class.parse('--foo = bar').first
    record[:name].should == 'foo'
    record[:value].should == 'bar'
    record[:record_type].should == :parsed
  end
  it 'should be able to parse settings without values' do
    record = @provider.class.parse('--foo').first
    record[:name].should == 'foo'
    record[:value].should == true
    record[:record_type].should == :parsed
  end
  it 'should be able to parse negated settings without values' do
    record = @provider.class.parse('--nofoo').first
    record[:name].should == 'foo'
    record[:value].should == false
    record[:record_type].should == :parsed
  end
  it 'should be able to parse values that have spaces' do
    record = @provider.class.parse('--foo = bar or baz').first
    record[:name].should == 'foo'
    record[:value].should == 'bar or baz'
    record[:record_type].should == :parsed
  end
  it 'should be able to parse values with equal signs' do
    record = @provider.class.parse('--foo = bar=baz').first
    record[:name].should == 'foo'
    record[:value].should == 'bar=baz'
    record[:record_type].should == :parsed
  end
  it 'should be able to create a valid line from a resource' do
    provider_class.to_line({:name => 'foo', :value => 'bar'}).should == '--foo=bar'
  end
  it 'should parse empty lines' do
    record = @provider.class.parse('       ').first
    record[:record_type].should == :blank
  end
  it 'should parse comment lines' do
    record = @provider.class.parse('  #--foo = bar').first
    record[:record_type].should == :comment
  end
end
