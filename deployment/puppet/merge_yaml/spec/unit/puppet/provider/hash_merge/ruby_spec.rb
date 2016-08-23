require 'spec_helper'

describe Puppet::Type.type(:hash_merge).provider(:ruby) do
  before(:each) do
    puppet_debug_override
  end

  let(:resource) do
    Puppet::Type.type(:hash_merge).new(
        {
            :title => '/tmp/test.yaml',
            :data => {'a' => '1'},
        }
    )
  end

  let(:provider) do
    resource.provider
  end

  subject do
    provider
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should be able to read YAML file' do
    resource[:type] = 'yaml'
    expect(provider).to receive(:read_file).and_return("---\na: '1'\n")
    expect(provider.read_data_from_file).to eq({'a' => '1'})
  end

  it 'should be able to read JSON file' do
    resource[:type] = 'json'
    expect(provider).to receive(:read_file).and_return('{"a":"1"}')
    expect(provider.read_data_from_file).to eq({'a' => '1'})
  end

  it 'should be able to write YAML file' do
    resource[:type] = 'yaml'
    expect(provider).to receive(:write_file) do |yaml|
      yaml == "---\na: '1'\n" or yaml == "--\n  a:'1'\n"
    end
    provider.write_data_to_file({'a' => '1'})
  end

  it 'should be able to write JSON file' do
    resource[:type] = 'json'
    expect(provider).to receive(:write_file).with('{"a":"1"}')
    provider.write_data_to_file({'a' => '1'})
  end

end
