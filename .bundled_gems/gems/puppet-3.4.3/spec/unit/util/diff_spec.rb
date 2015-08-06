#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/diff'
require 'puppet/util/execution'

describe Puppet::Util::Diff do
  describe ".diff" do
    it "should execute the diff command with arguments" do
      Puppet[:diff] = 'foo'
      Puppet[:diff_args] = 'bar'

      Puppet::Util::Execution.expects(:execute).with(['foo', 'bar', 'a', 'b'], {:failonfail => false, :combine => false}).returns('baz')
      subject.diff('a', 'b').should == 'baz'
    end

    it "should omit diff arguments if none are specified" do
      Puppet[:diff] = 'foo'
      Puppet[:diff_args] = ''

      Puppet::Util::Execution.expects(:execute).with(['foo', 'a', 'b'], {:failonfail => false, :combine => false}).returns('baz')
      subject.diff('a', 'b').should == 'baz'
    end

    it "should return empty string if the diff command is empty" do
      Puppet[:diff] = ''

      Puppet::Util::Execution.expects(:execute).never
      subject.diff('a', 'b').should == ''
    end
  end
end
