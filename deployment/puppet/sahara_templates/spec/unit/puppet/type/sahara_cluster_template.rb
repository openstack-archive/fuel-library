require 'puppet'

describe Puppet::Type.type(:sahara_cluster_template) do

  let(:resource) do
    Puppet::Type.type(:sahara_cluster_template).new({
      :name => 'test_cluster_template',
      :plugin_name => 'fake',
      :node_groups => [{'name' => 'master', 'count' => 1}],
      :hadoop_version => '0.1',
      :auth_password => 'password',
    })
  end

  it 'should have the name parameter' do
    expect(resource[:name]).to eq 'test_cluster_template'
  end

  it 'should have the plugin_name parameter' do
    expect(resource[:plugin_name]).to eq 'fake'
  end

  it 'should have the node_groups parameter' do
    expect(resource[:node_groups]).to eq [{'name' => 'master', 'count' => 1}]
  end

  it 'should have the hadoop_version parameter' do
    expect(resource[:hadoop_version]).to eq '0.1'
  end

end
