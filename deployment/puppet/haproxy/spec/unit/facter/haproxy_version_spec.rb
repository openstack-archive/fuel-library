require "spec_helper"

describe Facter::Util::Fact do
  before {
    Facter.clear
  }

  context "haproxy present" do
    it do
      haproxy_version_output = <<-EOS
      HA-Proxy version 1.5.3 2014/07/25
      Copyright 2000-2014 Willy Tarreau <w@1wt.eu>
      EOS
      Facter::Util::Resolution.expects(:which).with("haproxy").returns(true)
      Facter::Util::Resolution.expects(:exec).with("haproxy -v 2>&1").returns(haproxy_version_output)
      Facter.fact(:haproxy_version).value.should == "1.5.3"
    end
  end

  context "haproxy not present" do
    it do
      Facter::Util::Resolution.stubs(:exec)
      Facter::Util::Resolution.expects(:which).with("haproxy").returns(false)
      Facter.fact(:haproxy_version).should be_nil
    end
  end
end