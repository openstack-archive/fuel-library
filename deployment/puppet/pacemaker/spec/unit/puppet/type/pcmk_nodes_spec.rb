require 'spec_helper'

describe Puppet::Type.type(:pcmk_nodes) do
  subject do
    Puppet::Type.type(:pcmk_nodes).new(:name => 'pacemaker', :nodes => nodes_data)
  end

  let(:nodes_data) do
    {
        'node-1' => "192.168.0.1",
        'node-2' => "192.168.0.2",
        'node-3' => "192.168.0.3",
        'node-4' => "192.168.0.4",
    }
  end

  it "should have a 'name' parameter" do
    expect(subject[:name]).to eq 'pacemaker'
  end

  it "should have a 'nodes' parameter" do
    expect(subject[:nodes]).to eq nodes_data
  end

  it "should have a 'corosync_nodes' property that defaults to 'nodes' parameter" do
    expect(subject[:corosync_nodes]).to eq nodes_data.keys
  end

  it "should have a 'pacemaker_nodes' property that defaults to 'nodes' parameter" do
    expect(subject[:pacemaker_nodes]).to eq nodes_data.keys
  end

  it "should fail if nodes data is not provided or incorrect" do
    expect {
      subject[:nodes] = nil
    }.to raise_error
    expect {
      subject[:nodes] = 'node-1'
    }.to raise_error
  end

  it "should fail if there is no corosync_nodes" do
    expect {
      subject[:corosync_nodes] = nil
      subject.validate
    }.to raise_error
    expect {
      subject[:corosync_nodes] = []
      subject.validate
    }.to raise_error
  end

  it "should fail if there is no pacemaker_nodes" do
    expect {
      subject[:pacemaker_nodes] = nil
      subject.validate
    }.to raise_error
    expect {
      subject[:pacemaker_nodes] = []
      subject.validate
    }.to raise_error
  end

end
