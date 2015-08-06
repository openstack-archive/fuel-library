#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/property/ordered_list'

ordered_list_class = Puppet::Property::OrderedList

describe ordered_list_class do

  it "should be a subclass of List" do
    ordered_list_class.superclass.must == Puppet::Property::List
  end

  describe "as an instance" do
    before do
      # Wow that's a messy interface to the resource.
      ordered_list_class.initvars
      @resource = stub 'resource', :[]= => nil, :property => nil
      @property = ordered_list_class.new(:resource => @resource)
    end

    describe "when adding should to current" do
      it "should add the arrays when current is an array" do
        @property.add_should_with_current(["should"], ["current"]).should == ["should", "current"]
      end

      it "should return 'should' if current is not an array" do
        @property.add_should_with_current(["should"], :absent).should == ["should"]
      end

      it "should return only the uniq elements leading with the order of 'should'" do
        @property.add_should_with_current(["this", "is", "should"], ["is", "this", "current"]).should == ["this", "is", "should", "current"]
      end
    end

    describe "when calling should" do
      it "should return nil if @should is nil" do
        @property.should.must == nil
      end

      it "should return the values of @should (without sorting) as a string if inclusive" do
        @property.should = ["foo", "bar"]
        @property.expects(:inclusive?).returns(true)
        @property.should.must == "foo,bar"
      end

      it "should return the uniq values of @should + retrieve as a string if !inclusive with the @ values leading" do
        @property.should = ["foo", "bar"]
        @property.expects(:inclusive?).returns(false)
        @property.expects(:retrieve).returns(["foo","baz"])
        @property.should.must == "foo,bar,baz"
      end
    end

    describe "when calling dearrayify" do
      it "should join the array with the delimiter" do
        array = mock "array"
        array.expects(:join).with(@property.delimiter)
        @property.dearrayify(array)
      end
    end
  end
end
