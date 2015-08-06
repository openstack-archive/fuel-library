#! /usr/bin/env ruby
require 'spec_helper'

describe "the 'include' function" do
  before :all do
    Puppet::Parser::Functions.autoloader.loadall
  end

  before :each do
    Puppet::Node::Environment.stubs(:current).returns(nil)
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("foo"))
    @scope = Puppet::Parser::Scope.new(@compiler)
  end

  it "should exist" do
    Puppet::Parser::Functions.function("include").should == "function_include"
  end

  it "should include a single class" do
    inc = "foo"
    @compiler.expects(:evaluate_classes).with {|klasses,parser,lazy| klasses == [inc]}.returns([inc])
    @scope.function_include(["foo"])
  end

  it "should include multiple classes" do
    inc = ["foo","bar"]
    @compiler.expects(:evaluate_classes).with {|klasses,parser,lazy| klasses == inc}.returns(inc)
    @scope.function_include(["foo","bar"])
  end

  it "should include multiple classes passed in an array" do
    inc = ["foo","bar"]
    @compiler.expects(:evaluate_classes).with {|klasses,parser,lazy| klasses == inc}.returns(inc)
    @scope.function_include([["foo","bar"]])
  end

  it "should flatten nested arrays" do
    inc = ["foo","bar","baz"]
    @compiler.expects(:evaluate_classes).with {|klasses,parser,lazy| klasses == inc}.returns(inc)
    @scope.function_include([["foo","bar"],"baz"])
  end

  it "should not lazily evaluate the included class" do
    @compiler.expects(:evaluate_classes).with {|klasses,parser,lazy| lazy == false}.returns("foo")
    @scope.function_include(["foo"])
  end

  it "should raise if the class is not found" do
    @scope.stubs(:source).returns(true)
    expect { @scope.function_include(["nosuchclass"]) }.to raise_error Puppet::Error
  end
end
