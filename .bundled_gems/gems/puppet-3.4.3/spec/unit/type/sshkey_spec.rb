#! /usr/bin/env ruby
require 'spec_helper'

sshkey = Puppet::Type.type(:sshkey)

describe sshkey do
  before do
    @class = sshkey
  end

  it "should have :name its namevar" do
    @class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        @class.attrtype(param).should == :param
      end
    end

    [:host_aliases, :ensure, :key, :type].each do |property|
      it "should have a #{property} property" do
        @class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating values" do

    [:'ssh-dss', :'ssh-rsa', :rsa, :dsa, :'ecdsa-sha2-nistp256', :'ecdsa-sha2-nistp384', :'ecdsa-sha2-nistp521'].each do |keytype|
      it "should support #{keytype} as a type value" do
        proc { @class.new(:name => "foo", :type => keytype) }.should_not raise_error
      end
    end

    it "should alias :rsa to :ssh-rsa" do
      key = @class.new(:name => "foo", :type => :rsa)
      key.should(:type).should == :'ssh-rsa'
    end

    it "should alias :dsa to :ssh-dss" do
      key = @class.new(:name => "foo", :type => :dsa)
      key.should(:type).should == :'ssh-dss'
    end

    it "should not support values other than ssh-dss, ssh-rsa, dsa, rsa for type" do
      proc { @class.new(:name => "whev", :type => :'ssh-dsa') }.should raise_error(Puppet::Error)
    end

    it "should accept one host_alias" do
      proc { @class.new(:name => "foo", :host_aliases => 'foo.bar.tld') }.should_not raise_error
    end

    it "should accept multiple host_aliases as an array" do
      proc { @class.new(:name => "foo", :host_aliases => ['foo.bar.tld','10.0.9.9']) }.should_not raise_error
    end

    it "should not accept spaces in any host_alias" do
      proc { @class.new(:name => "foo", :host_aliases => ['foo.bar.tld','foo bar']) }.should raise_error(Puppet::Error)
    end

    it "should not accept aliases in the resourcename" do
      proc { @class.new(:name => 'host,host.domain,ip') }.should raise_error(Puppet::Error)
    end

  end
end
