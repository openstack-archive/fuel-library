require 'spec_helper'

describe "the nodes_to_node_port_list function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it "should exist" do
    Puppet::Parser::Functions.function("nodes_to_node_port_list").should == "function_nodes_to_node_port_list"
  end

  it "should return correct result with correct input and string port" do
    result = scope.function_nodes_to_node_port_list([[{'name' => 'node1'}, {'name' => 'node2'}], '123'])
    result.should(eq('node1:123, node2:123'))
  end

  it "should return correct result with correct input and numeric port" do
    result = scope.function_nodes_to_node_port_list([[{'name' => 'node1'}, {'name' => 'node2'}], 123])
    result.should(eq('node1:123, node2:123'))
  end

  it "should return correct result with correct input and default port" do
    result = scope.function_nodes_to_node_port_list([[{'name' => 'node1'}, {'name' => 'node2'}]])
    result.should(eq('node1:8084, node2:8084'))
  end

  it "should return empty string with incorrect empty input" do
    result = scope.function_nodes_to_node_port_list([[]])
    result.should(eq(''))
  end

  it "should return empty string with incorrect letters instead of port" do
    result = scope.function_nodes_to_node_port_list([[{'name' => 'node1'}, {'name' => 'node2'}],'1asd2f'])
    result.should(eq(''))
  end

  it "should return empty string with port out of range" do
    result = scope.function_nodes_to_node_port_list([[{'name' => 'node1'}, {'name' => 'node2'}],100000])
    result.should(eq(''))
  end

  it "should return empty string with empty hash" do
    result = scope.function_nodes_to_node_port_list([[{}, {}],100])
    result.should(eq(''))
  end

end
