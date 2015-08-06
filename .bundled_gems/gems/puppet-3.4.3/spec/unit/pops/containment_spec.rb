require 'spec_helper'
require 'puppet/pops'
require File.join(File.dirname(__FILE__), 'factory_rspec_helper')

describe Puppet::Pops::Containment do
  include FactoryRspecHelper

  it "Should return an Enumerable if eAllContents is called without arguments" do
    (literal(1) + literal(2)).current.eAllContents.is_a?(Enumerable).should == true
  end

  it "Should return all content" do
    # Note the top object is not included (an ArithmeticOperation with + operator)
    (literal(1) + literal(2) + literal(3)).current.eAllContents.collect {|x| x}.size.should == 4
  end

  it "Should return containing feature" do
    left = literal(1)
    right = literal(2)
    op = left + right

    #pending "eContainingFeature does not work on _uni containments in RGen < 0.6.1"
    left.current.eContainingFeature.should == :left_expr
    right.current.eContainingFeature.should == :right_expr
  end
end
