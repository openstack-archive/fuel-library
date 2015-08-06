#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/indirector/node/exec'
require 'puppet/indirector/request'

describe Puppet::Node::Exec do
  before do
    @indirection = mock 'indirection'
    Puppet.settings[:external_nodes] = File.expand_path("/echo")
    @searcher = Puppet::Node::Exec.new
  end

  describe "when constructing the command to run" do
    it "should use the external_node script as the command" do
      Puppet[:external_nodes] = "/bin/echo"
      @searcher.command.should == %w{/bin/echo}
    end

    it "should throw an exception if no external node command is set" do
      Puppet[:external_nodes] = "none"
      proc { @searcher.find(stub('request', :key => "foo")) }.should raise_error(ArgumentError)
    end
  end

  describe "when handling the results of the command" do
    before do
      @name = "yay"
      @node = Puppet::Node.new(@name)
      @node.stubs(:fact_merge)
      Puppet::Node.expects(:new).with(@name).returns(@node)
      @result = {}
      # Use a local variable so the reference is usable in the execute definition.
      result = @result
      @searcher.meta_def(:execute) do |command, arguments|
        return YAML.dump(result)
      end

      @request = Puppet::Indirector::Request.new(:node, :find, @name, nil)
    end

    it "should translate the YAML into a Node instance" do
      # Use an empty hash
      @searcher.find(@request).should equal(@node)
    end

    it "should set the resulting parameters as the node parameters" do
      @result[:parameters] = {"a" => "b", "c" => "d"}
      @searcher.find(@request)
      @node.parameters.should == {"a" => "b", "c" => "d"}
    end

    it "should set the resulting classes as the node classes" do
      @result[:classes] = %w{one two}
      @searcher.find(@request)
      @node.classes.should == [ 'one', 'two' ]
    end

    it "should merge the node's facts with its parameters" do
      @node.expects(:fact_merge)
      @searcher.find(@request)
    end

    it "should set the node's environment if one is provided" do
      @result[:environment] = "yay"
      @searcher.find(@request)
      @node.environment.to_s.should == 'yay'
    end

    it "should set the node's environment based on the request if not otherwise provided" do
      @request.environment = "boo"
      @searcher.find(@request)
      @node.environment.to_s.should == 'boo'
    end
  end
end
