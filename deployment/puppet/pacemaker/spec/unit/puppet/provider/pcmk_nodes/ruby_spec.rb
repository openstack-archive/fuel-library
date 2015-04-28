require 'spec_helper'

describe Puppet::Type.type(:pcmk_nodes).provider(:ruby) do

  let(:resource) do
    Puppet::Type.type(:pcmk_nodes).new(
        :name => 'paceamker',
        :provider=> :ruby
    )
  end

  let(:provider) do
    provider = resource.provider
    if ENV['PUPPET_DEBUG']
      class << provider
        def debug(str)
          puts str
        end
      end
    end
    provider
  end

  let(:cmap_nodelist) do
    <<-eos
####
nodelist.node.0.nodeid (u32) = 1
nodelist.node.0.ring0_addr (str) = 192.168.0.1
nodelist.node.1.nodeid (u32) = 2
nodelist.node.1.ring0_addr (str) = 192.168.0.2
nodelist.node.2.nodeid (u32) = 3
nodelist.node.2.ring0_addr (str) = 192.168.0.3
#####
    eos
  end

  let(:pacemaker_nodes_structure) do
    {
        "node-1" => "1",
        "node-2" => "2",
        "node-3" => "3",
    }
  end

  let(:corosync_nodes_structure) do
    {
        "node-1" => { :nodeid => "1", :number => "0", :name=>"node-1", :ring0_addr => "192.168.0.1" },
        "node-2" => { :nodeid => "2", :number => "1", :name=>"node-2", :ring0_addr => "192.168.0.2" },
        "node-3" => { :nodeid => "3", :number => "2", :name=>"node-3", :ring0_addr => "192.168.0.3" },
    }
  end

  let(:existing_nodes) do
    %w(node-1 node-2 node-3)
  end

  let(:expected_nodes) do
    %w(node-2 node-3 node-4)
  end

  before(:each) do
    provider.stubs(:cmapctl_nodelist).returns cmap_nodelist
    provider.stubs(:pacemaker_nodes_structure).returns pacemaker_nodes_structure
    provider.stubs(:pacemaker_nodes_states_structure).returns pacemaker_nodes_structure
  end

  it 'returns the corosync_nodes_structure' do
    expect(provider.corosync_nodes_structure).to eq(corosync_nodes_structure)
  end

  it 'can get corosync_nodes' do
    expect(provider.corosync_nodes).to eq existing_nodes
  end

  it 'can get pacemaker_nodes' do
    expect(provider.pacemaker_nodes).to eq existing_nodes
  end

  it 'can get pacemaker_nodes_states' do
    expect(provider.pacemaker_nodes_states).to eq existing_nodes
  end

  it 'removes unexpected existing corosync_nodes' do
    provider.corosync_nodes = expected_nodes
  end

  it 'adds missing corosync_nodes' do
    provider.corosync_nodes = expected_nodes
  end

  it 'removes unexpected existing pacemaker_nodes' do
    provider.pacemaker_nodes = expected_nodes
  end

  it 'removes unexpected existing pacemaker_nodes_states' do
    provider.pacemaker_nodes_states = expected_nodes
  end

end
