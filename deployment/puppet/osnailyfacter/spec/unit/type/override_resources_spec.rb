require 'puppet'
require 'puppet/type/override_resources'

describe Puppet::Type.type(:override_resources) do

  before :each do
    @overres = Puppet::Type.type(:override_resources).new(
      :type     => 'keystone_config',
      :data     => {},
      :defaults => {}
    )
  end

  it 'should accept a config' do
    @overres[:name] = 'keystone_config'
    expect(@overres[:name]).to eq('keystone_config')
  end

  it 'should require a name' do
    expect {
      Puppet::Type.type(:override_resources).new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should be a resource type to override' do
    expect {
      @overres[:type] = ''
      @overres.generate
    }.to raise_error(Puppet::Error, /Title should be a resource type to override!$/)
  end

  it 'should contain resource hash' do
    expect {
      @overres[:data] = 'string => data'
      @overres.generate
    }.to raise_error(Puppet::Error, /Data should contain resource hash!$/)
  end

  it 'should contain resource defaults hash' do
    expect {
      @overres[:defaults] = 'string => data'
      @overres.generate
    }.to raise_error(Puppet::Error, /Defaults should contain resource defaults hash!$/)
  end

  it 'should accept a resource type' do
    type = 'keystone_config'
    @overres[:type] = type
    expect(@overres[:type]).to eq(type)
  end

  it 'should accept an override data' do
    data = {
      'DEFAULT/debug' => { 'value' => false },
      'DEFAULT/max_param_size' => { 'value' => 128 }
    }
    @overres[:data] = data
    expect(@overres[:data]).to eq(data)
  end

end
