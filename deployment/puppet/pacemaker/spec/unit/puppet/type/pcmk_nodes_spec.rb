require 'spec_helper'

describe Puppet::Type.type(:pcmk_nodes) do
  subject do
    Puppet::Type.type(:pcmk_nodes).new(:name => 'pacemaker', :nodes => nodes)
  end

  let(:nodes) { %w(node-1 node-2 node-3) }

  it "should have a 'name' parameter" do
    expect(subject[:name]).to eq 'pacemaker'
  end

  it "should have a 'nodes' parameter" do
    expect(subject[:nodes]).to eq nodes
  end

  it "should have a 'corosync_nodes' property that defaults to 'nodes' parameter" do
    expect(subject[:corosync_nodes]).to eq nodes
  end

  it "should have a 'pacemaker_nodes' property that defaults to 'nodes' parameter" do
    expect(subject[:pacemaker_nodes]).to eq nodes
  end

end
