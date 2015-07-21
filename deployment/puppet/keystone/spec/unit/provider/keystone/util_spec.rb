require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone'
require 'puppet/provider/keystone/util'

describe "split_domain method" do
  it 'should handle nil and empty strings' do
    expect(Util.split_domain('')).to eq([nil, nil])
    expect(Util.split_domain(nil)).to eq([nil, nil])
  end
  it 'should return name and no domain' do
    expect(Util.split_domain('foo')).to eq(['foo', nil])
    expect(Util.split_domain('foo::')).to eq(['foo', nil])
  end
  it 'should return name and domain' do
    expect(Util.split_domain('foo::bar')).to eq(['foo', 'bar'])
    expect(Util.split_domain('foo::bar::')).to eq(['foo', 'bar'])
    expect(Util.split_domain('::foo::bar')).to eq(['::foo', 'bar'])
    expect(Util.split_domain('::foo::bar::')).to eq(['::foo', 'bar'])
    expect(Util.split_domain('foo::bar::baz')).to eq(['foo::bar', 'baz'])
    expect(Util.split_domain('foo::bar::baz::')).to eq(['foo::bar', 'baz'])
    expect(Util.split_domain('::foo::bar::baz')).to eq(['::foo::bar', 'baz'])
    expect(Util.split_domain('::foo::bar::baz::')).to eq(['::foo::bar', 'baz'])
  end
  it 'should return domain only' do
    expect(Util.split_domain('::foo')).to eq([nil, 'foo'])
    expect(Util.split_domain('::foo::')).to eq([nil, 'foo'])
  end
end
