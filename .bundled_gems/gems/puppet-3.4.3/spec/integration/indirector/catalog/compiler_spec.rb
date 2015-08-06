#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/resource/catalog'

Puppet::Resource::Catalog.indirection.terminus(:compiler)

describe Puppet::Resource::Catalog::Compiler do
  before do
    Facter.stubs(:value).returns "something"
    @catalog = Puppet::Resource::Catalog.new
    @catalog.add_resource(@one = Puppet::Resource.new(:file, "/one"))
    @catalog.add_resource(@two = Puppet::Resource.new(:file, "/two"))
  end

  after { Puppet.settings.clear }

  it "should remove virtual resources when filtering" do
    @one.virtual = true
    Puppet::Resource::Catalog.indirection.terminus.filter(@catalog).resource_refs.should == [ @two.ref ]
  end

  it "should not remove exported resources when filtering" do
    @one.exported = true
    Puppet::Resource::Catalog.indirection.terminus.filter(@catalog).resource_refs.sort.should == [ @one.ref, @two.ref ]
  end

  it "should remove virtual exported resources when filtering" do
    @one.exported = true
    @one.virtual = true
    Puppet::Resource::Catalog.indirection.terminus.filter(@catalog).resource_refs.should == [ @two.ref ]
  end

  it "should filter out virtual resources when finding a catalog" do
    Puppet[:node_terminus] = :memory
    Puppet::Node.indirection.save(Puppet::Node.new("mynode"))
    Puppet::Resource::Catalog.indirection.terminus.stubs(:extract_facts_from_request)
    Puppet::Resource::Catalog.indirection.terminus.stubs(:compile).returns(@catalog)

    @one.virtual = true

    Puppet::Resource::Catalog.indirection.find("mynode").resource_refs.should == [ @two.ref ]
  end

  it "should not filter out exported resources when finding a catalog" do
    Puppet[:node_terminus] = :memory
    Puppet::Node.indirection.save(Puppet::Node.new("mynode"))
    Puppet::Resource::Catalog.indirection.terminus.stubs(:extract_facts_from_request)
    Puppet::Resource::Catalog.indirection.terminus.stubs(:compile).returns(@catalog)

    @one.exported = true

    Puppet::Resource::Catalog.indirection.find("mynode").resource_refs.sort.should == [ @one.ref, @two.ref ]
  end

  it "should filter out virtual exported resources when finding a catalog" do
    Puppet[:node_terminus] = :memory
    Puppet::Node.indirection.save(Puppet::Node.new("mynode"))
    Puppet::Resource::Catalog.indirection.terminus.stubs(:extract_facts_from_request)
    Puppet::Resource::Catalog.indirection.terminus.stubs(:compile).returns(@catalog)

    @one.exported = true
    @one.virtual = true

    Puppet::Resource::Catalog.indirection.find("mynode").resource_refs.should == [ @two.ref ]
  end
end
