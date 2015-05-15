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
    if ENV['SPEC_PUPPET_DEBUG']
      class << provider
        def debug(str)
          puts str
        end
      end
    end
    provider
  end

  # output of corosync_cmapctl -b nodelist
  let(:cmap_nodelist) do
    <<-eos
nodelist.node.0.nodeid (u32) = 1
nodelist.node.0.ring0_addr (str) = 192.168.0.1
nodelist.node.1.nodeid (u32) = 2
nodelist.node.1.ring0_addr (str) = 192.168.0.2
nodelist.node.2.nodeid (u32) = 3
nodelist.node.2.ring0_addr (str) = 192.168.0.3
    eos
  end

  # comes from 'nodes' library method excluing unrelated data
  let(:nodes_input) do
    {
        "node-1" => {'id' => "1", 'uname' => "node-1"},
        "node-2" => {'id' => "2", 'uname' => "node-2"},
        "node-3" => {'id' => "3", 'uname' => "node-3"},
    }
  end

  # comes from 'node_ids' library method
  let(:node_ids_input) do
    {
        "node-1" => {'id' => "1", 'uname' => "node-1"},
        "node-2" => {'id' => "2", 'uname' => "node-2"},
        "node-3" => {'id' => "3", 'uname' => "node-3"},
    }
  end

  # retreived corosync nodes state
  let(:corosync_nodes_state) do
    {
        "0"=>{ "id" => "1", "number" => "0", "ip" => "192.168.0.1" },
        "1"=>{ "id" => "2", "number" => "1", "ip" => "192.168.0.2" },
        "2"=>{ "id" => "3", "number" => "2", "ip" => "192.168.0.3" },
    }
  end

  # generated existing paceamker nodes structure
  let(:pacemaker_nodes_structure) do
    {
        "node-1" => "1",
        "node-2" => "2",
        "node-3" => "3",
    }
  end

  # generated existing corosync nodes structure
  let(:corosync_nodes_structure) do
    {
        "1" => "192.168.0.1",
        "2" => "192.168.0.2",
        "3" => "192.168.0.3",
    }
  end

  # comes from 'constraint_locations' library method
  let(:constraint_locations_input) do
    {
        "p_neutron-dhcp-agent_on_node-1" => {"id" => "p_neutron-dhcp-agent_on_node-1", "node" => "node-1", "rsc" => "p_neutron-dhcp-agent", "score" => "100"},
        "p_neutron-dhcp-agent_on_node-2" => {"id" => "p_neutron-dhcp-agent_on_node-2", "node" => "node-2", "rsc" => "p_neutron-dhcp-agent", "score" => "100"},
        "p_neutron-dhcp-agent_on_node-3" => {"id" => "p_neutron-dhcp-agent_on_node-3", "node" => "node-3", "rsc" => "p_neutron-dhcp-agent", "score" => "100"},
        "clone_p_haproxy_on_node-1" => {"id" => "clone_p_haproxy_on_node-1", "node" => "node-1", "rsc" => "clone_p_haproxy", "score" => "100"},
        "clone_p_haproxy_on_node-2" => {"id" => "clone_p_haproxy_on_node-2", "node" => "node-2", "rsc" => "clone_p_haproxy", "score" => "100"},
        "clone_p_haproxy_on_node-3" => {"id" => "clone_p_haproxy_on_node-3", "node" => "node-3", "rsc" => "clone_p_haproxy", "score" => "100"},
    }
  end

  # 'nodes' parameter when nodes should be added and removed
  let(:nodes_data) do
    {
        'node-2' => { "ip" => "192.168.0.2", "id" => "2" },
        'node-3' => { "ip" => "192.168.0.3", "id" => "3" },
        'node-4' => { "ip" => "192.168.0.4", "id" => "4" },
    }
  end

  # 'nodes' parameter when fqdn should be switched to name
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
    provider.stubs(:node_ids).returns node_ids_input
    provider.stubs(:nodes).returns nodes_input
    provider.stubs(:constraint_locations).returns constraint_locations_input
    provider.stubs(:node_name).returns 'node-2'
    provider.stubs(:wait_for_online).returns true
  end


  context 'data structures' do
    it 'corosync_nodes_state' do
      expect(provider.corosync_nodes_state).to eq(corosync_nodes_state)
    end

    it 'corosync_nodes_structure' do
      expect(provider.corosync_nodes_structure).to eq(corosync_nodes_structure)
    end

    it 'pacemaker_nodes_structure' do
      expect(provider.pacemaker_nodes_structure).to eq(pacemaker_nodes_structure)
    end

  end

  context 'main actions' do
    before(:each) do
      provider.stubs(:add_corosync_node)
      provider.stubs(:remove_corosync_node)
      provider.stubs(:add_pacemaker_node)
      provider.stubs(:remove_pacemaker_node)
    end

    it 'can get corosync_nodes' do
      expect(provider.corosync_nodes).to eq corosync_nodes_structure
    end

    it 'can get pacemaker_nodes' do
      expect(provider.pacemaker_nodes).to eq pacemaker_nodes_structure
    end

    it 'removes unexpected corosync_nodes' do
      provider.expects(:remove_corosync_node).with('1')
      provider.corosync_nodes = resource[:corosync_nodes]
    end

    it 'adds missing corosync_nodes' do
      provider.expects(:add_corosync_node).with('4')
      provider.corosync_nodes = resource[:corosync_nodes]
    end

    it 'removes unexpected pacemaker_nodes' do
      provider.expects(:remove_pacemaker_node).with('node-1')
      provider.pacemaker_nodes = resource[:pacemaker_nodes]
    end

    it 'adds missing pacemaker_nodes' do
      provider.expects(:add_pacemaker_node).with('node-4')
      provider.pacemaker_nodes = resource[:pacemaker_nodes]
    end

  end

  context 'when adding a new pacemaker_node' do

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
      provider.stubs(:remove_pacemaker_crm_node)
      provider.stubs(:remove_location_constraint)
    end

    it 'removes the crm_node record' do
      provider.expects(:remove_pacemaker_crm_node).with 'node-1'
      provider.remove_pacemaker_node 'node-1'
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

    it 'cat get a new free corosync nodes number' do
      expect(provider.next_corosync_node_number).to eq '3'
    end

    it 'adds a new corosync node with the correct parameters' do
      provider.expects(:add_corosync_node_record).with '3', '192.168.0.4', '4'
      provider.add_corosync_node '4'
    end
  end

  context 'when removing a corosync_node' do

    it 'removes a node with the correct number' do
      provider.expects(:remove_corosync_node_record).with '0'
      provider.remove_corosync_node '1'
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
