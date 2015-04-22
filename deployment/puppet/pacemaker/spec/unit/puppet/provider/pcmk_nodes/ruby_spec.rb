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

  let(:nodes_states) do
    {
        "node-1" => { 'id' => "1", 'uname' => "node-1" },
        "node-2" => { 'id' => "2", 'uname' => "node-2" },
        "node-3" => { 'id' => "3", 'uname' => "node-3" },
    }
  end

  let(:corosync_nodes_structure) do
    {
        "node-1" => { 'id' => "1", 'number' => "0", 'uname' => "node-1", 'ring0_addr' => "192.168.0.1" },
        "node-2" => { 'id' => "2", 'number' => "1", 'uname' => "node-2", 'ring0_addr' => "192.168.0.2" },
        "node-3" => { 'id' => "3", 'number' => "2", 'uname' => "node-3", 'ring0_addr' => "192.168.0.3" },
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
    provider.stubs(:node_ids).returns pacemaker_nodes_structure
    provider.stubs(:nodes).returns nodes_states
  end

  context 'data structures' do
    it 'corosync_nodes_structure' do
      expect(provider.corosync_nodes_structure).to eq(corosync_nodes_structure)
    end

    it 'pacemaker_nodes_structure' do
      expect(provider.pacemaker_nodes_structure).to eq(pacemaker_nodes_structure)
    end

  end

  context 'main actions' do
    it 'can get corosync_nodes' do
      expect(provider.corosync_nodes).to eq existing_nodes
    end

    it 'can get pacemaker_nodes' do
      expect(provider.pacemaker_nodes).to eq existing_nodes
    end

    it 'removes unexpected corosync_nodes' do
      provider.corosync_nodes = expected_nodes
    end

    it 'adds missing corosync_nodes' do
      provider.corosync_nodes = expected_nodes
    end

    it 'removes unexpected pacemaker_nodes' do
      provider.pacemaker_nodes = expected_nodes
    end

    it 'cleans out node based locations when a node is removed' do

    end
  end

end
