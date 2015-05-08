require 'spec_helper'

describe Puppet::Type.type(:pcmk_nodes).provider(:ruby) do

  let(:resource) do
    Puppet::Type.type(:pcmk_nodes).new(
        :name => 'paceamker',
        :provider => :ruby,
        :nodes => nodes_data,
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
nodelist.node.1.nodeid (u32) = 1
nodelist.node.1.ring0_addr (str) = 192.168.0.1
nodelist.node.2.nodeid (u32) = 2
nodelist.node.2.ring0_addr (str) = 192.168.0.2
nodelist.node.3.nodeid (u32) = 3
nodelist.node.3.ring0_addr (str) = 192.168.0.3
#####
    eos
  end

  let(:pacemaker_nodes_structure) do
    {
        "node-1" => {'id' => "1", 'uname' => "node-1"},
        "node-2" => {'id' => "2", 'uname' => "node-2"},
        "node-3" => {'id' => "3", 'uname' => "node-3"},
    }
  end

  let(:nodes_states) do
    {
        "node-1" => {'id' => "1", 'uname' => "node-1"},
        "node-2" => {'id' => "2", 'uname' => "node-2"},
        "node-3" => {'id' => "3", 'uname' => "node-3"},
    }
  end

  let(:corosync_nodes_structure) do
    {
        "node-1" => {'id' => "1", 'number' => "1", 'uname' => "node-1", 'ip' => "192.168.0.1"},
        "node-2" => {'id' => "2", 'number' => "2", 'uname' => "node-2", 'ip' => "192.168.0.2"},
        "node-3" => {'id' => "3", 'number' => "3", 'uname' => "node-3", 'ip' => "192.168.0.3"},
    }
  end

  let(:constraint_locations) do
    {
        "p_neutron-dhcp-agent_on_node-1" => {"id" => "p_neutron-dhcp-agent_on_node-1", "node" => "node-1", "rsc" => "p_neutron-dhcp-agent", "score" => "100"},
        "p_neutron-dhcp-agent_on_node-2" => {"id" => "p_neutron-dhcp-agent_on_node-2", "node" => "node-2", "rsc" => "p_neutron-dhcp-agent", "score" => "100"},
        "p_neutron-dhcp-agent_on_node-3" => {"id" => "p_neutron-dhcp-agent_on_node-3", "node" => "node-3", "rsc" => "p_neutron-dhcp-agent", "score" => "100"},
        "clone_p_haproxy_on_node-1" => {"id" => "clone_p_haproxy_on_node-1", "node" => "node-1", "rsc" => "clone_p_haproxy", "score" => "100"},
        "clone_p_haproxy_on_node-2" => {"id" => "clone_p_haproxy_on_node-2", "node" => "node-2", "rsc" => "clone_p_haproxy", "score" => "100"},
        "clone_p_haproxy_on_node-3" => {"id" => "clone_p_haproxy_on_node-3", "node" => "node-3", "rsc" => "clone_p_haproxy", "score" => "100"},
    }
  end

  let(:nodes_data) do
    {
        'node-1' => { "ip" => "192.168.0.1", "id" => "1" },
        'node-2' => { "ip" => "192.168.0.2", "id" => "2" },
        'node-3' => { "ip" => "192.168.0.3", "id" => "3" },
    }
  end

  let(:nodes_data_expected) do
    {
        'node-2' => { "ip" => "192.168.0.2", "id" => "2" },
        'node-3' => { "ip" => "192.168.0.3", "id" => "3" },
        'node-4' => { "ip" => "192.168.0.4", "id" => "4" },
    }
  end

  let(:fqdn_nodes_data) do
    data = {}
    nodes_data.each do |name, node|
      name = "#{name}.example.com"
      data[name] = node
    end
    data
  end

  before(:each) do
    provider.stubs(:cmapctl_nodelist).returns cmap_nodelist
    provider.stubs(:node_ids).returns pacemaker_nodes_structure
    provider.stubs(:nodes).returns nodes_states
    provider.stubs(:constraint_locations).returns constraint_locations
    provider.stubs(:node_name).returns 'node-1'
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
      expect(provider.corosync_nodes).to eq corosync_nodes_structure
    end

    it 'can get pacemaker_nodes' do
      expect(provider.pacemaker_nodes).to eq pacemaker_nodes_structure
    end

    it 'removes unexpected corosync_nodes' do
      provider.expects(:remove_corosync_node).with('node-1')
      provider.stubs(:add_corosync_node)
      provider.corosync_nodes = nodes_data_expected
    end

    it 'adds missing corosync_nodes' do
      provider.expects(:add_corosync_node).with('node-4')
      provider.stubs(:remove_corosync_node)
      provider.corosync_nodes = nodes_data_expected
    end

    it 'removes unexpected pacemaker_nodes' do
      provider.expects(:remove_pacemaker_node).with('node-1')
      provider.stubs(:add_pacemaker_node)
      provider.pacemaker_nodes = nodes_data_expected
    end

    it 'adds missing pacemaker_nodes' do
      provider.expects(:add_pacemaker_node).with('node-4')
      provider.stubs(:remove_pacemaker_node)
      provider.pacemaker_nodes = nodes_data_expected
    end

    it 'can compare hashes by keys' do
      expect(
          provider.compare_hashes_by_keys(
              {'a' => 1, 'b' => 2},
              {'a' => 1, 'c' => 3},
              'a')
      ).to eq true
      expect(
          provider.compare_hashes_by_keys(
              {'a' => 1, 'b' => 2},
              {'a' => 1, 'c' => 3},
              'b')
      ).to eq false
    end

  end

  context 'when adding a new pacemaker_node' do
    before(:each) do
      provider.stubs(:nodes_data).returns nodes_data_expected
    end

    it 'it adds a node record' do
      provider.expects(:add_pacemaker_node_record).with('node-4', '4')
      provider.stubs(:add_pacemaker_node_state)
      provider.add_pacemaker_node 'node-4'
    end

    it 'adds a node_state record' do
      provider.stubs(:add_pacemaker_node_record)
      provider.expects(:add_pacemaker_node_state).with('node-4', '4')
      provider.add_pacemaker_node 'node-4'
    end
  end

  context 'when removing a paceamker_node' do
    before(:each) do
      provider.stubs(:remove_pacemaker_node_state)
      provider.stubs(:remove_pacemaker_node_record)
      provider.stubs(:remove_location_constraint)
    end

    it 'cleans out node record' do
      provider.expects(:remove_pacemaker_node_record).with 'node-1'
      provider.remove_pacemaker_node 'node-1'
    end

    it 'cleans out node states' do
      provider.expects(:remove_pacemaker_node_state).with 'node-1'
      provider.remove_pacemaker_node 'node-1'
    end

    it 'cleans out node based locations' do
      provider.expects(:remove_location_constraint).with 'p_neutron-dhcp-agent_on_node-1'
      provider.expects(:remove_location_constraint).with 'clone_p_haproxy_on_node-1'
      provider.remove_pacemaker_node 'node-1'
    end
  end

  context 'when adding a new corosync_node' do
    before(:each) do
      provider.stubs(:nodes_data).returns nodes_data_expected
    end

    it 'adds a new corosync node with the correct parameters' do
      provider.expects(:add_corosync_node_record).with '4', "192.168.0.4", '4'
      provider.add_corosync_node 'node-4'
    end
  end

  context 'when removing a corosync_node' do
    it 'removes a node with the correct number' do
      provider.expects(:remove_corosync_node_record).with '1'
      provider.remove_corosync_node 'node-1'
    end
  end

  context 'FQDN and Hostname compatibility' do
    let(:resource) do
      Puppet::Type.type(:pcmk_nodes).new(
          :name => 'paceamker',
          :provider => :ruby,
          :nodes => fqdn_nodes_data,
      )
    end

    it 'can determine when the switch is needed' do
      expect(provider.change_fqdn_to_name?).to eq true
    end

    it 'can rewrite fqdns in the node input data to the hostnames' do
      provider.change_fqdn_to_name
      expect(provider.resource[:nodes]).to eq nodes_data
      expect(provider.corosync_nodes_structure).to eq(corosync_nodes_structure)
    end
  end

end
