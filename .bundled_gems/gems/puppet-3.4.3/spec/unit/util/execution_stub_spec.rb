#! /usr/bin/env ruby
require 'spec_helper'

describe Puppet::Util::ExecutionStub do
  it "should use the provided stub code when 'set' is called" do
    Puppet::Util::ExecutionStub.set do |command, options|
      command.should == ['/bin/foo', 'bar']
      "stub output"
    end
    Puppet::Util::ExecutionStub.current_value.should_not == nil
    Puppet::Util::Execution.execute(['/bin/foo', 'bar']).should == "stub output"
  end

  it "should automatically restore normal execution at the conclusion of each spec test" do
    # Note: this test relies on the previous test creating a stub.
    Puppet::Util::ExecutionStub.current_value.should == nil
  end

  it "should restore normal execution after 'reset' is called" do
    # Note: "true" exists at different paths in different OSes
    if Puppet.features.microsoft_windows?
      true_command = [Puppet::Util.which('cmd.exe').tr('/', '\\'), '/c', 'exit 0']
    else
      true_command = [Puppet::Util.which('true')]
    end
    stub_call_count = 0
    Puppet::Util::ExecutionStub.set do |command, options|
      command.should == true_command
      stub_call_count += 1
      'stub called'
    end
    Puppet::Util::Execution.execute(true_command).should == 'stub called'
    stub_call_count.should == 1
    Puppet::Util::ExecutionStub.reset
    Puppet::Util::ExecutionStub.current_value.should == nil
    Puppet::Util::Execution.execute(true_command).should == ''
    stub_call_count.should == 1
  end
end
