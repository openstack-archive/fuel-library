require 'puppet'

describe Puppet::Type.type(:sahara_node_group_template) do

  let(:resource) do
    Puppet::Type.type(:sahara_node_group_template).new({
      :name => 'test_template',
      :plugin_name => 'fake',
      :flavor_id => '0',
      :node_processes => [ 'none' ],
      :hadoop_version => '0.1',
      :auth_password => 'password',
    })
  end

  it 'should have the name parameter' do
    expect(resource[:name]).to eq 'test_template'
  end

  it 'should have the plugin_name parameter' do
    expect(resource[:plugin_name]).to eq 'fake'
  end

  it 'should have the flavor_id parameter' do
    expect(resource[:flavor_id]).to eq '0'
  end

  it 'should have the node_processes parameter' do
    expect(resource[:node_processes]).to eq ['none']
  end

  it 'should have the hadoop_version parameter' do
    expect(resource[:hadoop_version]).to eq '0.1'
  end

end
