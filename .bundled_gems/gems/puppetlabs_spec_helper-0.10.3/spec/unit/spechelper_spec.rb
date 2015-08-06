#!/usr/bin/env ruby
require 'puppetlabs_spec_helper/puppet_spec_helper'

# ensure we can access puppet settings outside of any example group
Puppet[:confdir]

# set modulepath from which to load custom type
Puppet[:modulepath] = File.join(File.dirname(__FILE__), '..', '..')

def should_be_able_to_load_types?
  return true if Puppet::Test::TestHelper.respond_to?(:initialize)

  case Puppet.version
  when /^2\.7\.20/
    false
  when /^3\.0\./
    false
  else
    true
  end
end

# construct a top-level describe block whose declared_class is a custom type in this module
describe Puppet::Type.type(:spechelper) do
  it "should load the type from the modulepath" do
    pending("this is only supported on newer versions of puppet", :unless => should_be_able_to_load_types?) do
      described_class.should be
    end
  end

  it "should have a doc string" do
    pending("this is only supported on newer versions of puppet", :unless => should_be_able_to_load_types?) do
      described_class.doc.should == "This is the spechelper type"
    end
  end
end

describe "Setup of settings" do
  it "sets confdir and vardir to something not meaningful to force tests to make their choice explicit" do
    Puppet[:confdir].should == "/dev/null"
    Puppet[:vardir].should == "/dev/null"
  end
end
