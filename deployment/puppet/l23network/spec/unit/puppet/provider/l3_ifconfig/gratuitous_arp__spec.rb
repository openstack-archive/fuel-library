require 'spec_helper'

describe Puppet::Type.type(:l3_ifconfig).provider(:lnx) do

  let(:resource) {
    Puppet::Type.type(:l3_ifconfig).new(
      :name      => 'eth1',
      :interface => 'eth1',
      :ensure    => :present,
      :ipaddr    => ["10.99.1.4/24"],
      :gateway   => :absent,
      :provider  => :lnx
    )
  }

  let(:provider) { resource.provider }
  let(:instance) { provider.class.instances }

  describe "l3_ifconfig " do
    before(:each) do
      provider.class.stubs(:arping).with('-U', '-c 32', '-w 5', '-I', 'eth1', '10.99.1.4').returns(true)
      provider.class.stubs(:iproute)
      provider.class.stubs(:iproute).with(['route', 'del', 'default', 'dev', 'eth1']).raises(Puppet::ExecutionFailure)
    end

    it "Assign IP address to the NIC" do
      provider.class.stubs(:arping).with('-D', '-c 32', '-w 5', '-I', 'eth1', '10.99.1.4').returns(true)
      provider.expects(:warn).with { |arg| arg =~ /IP\s+duplication/ }.never
      provider.create
      provider.flush
    end

    it "Assign duplication IP address to the NIC" do
      provider.class.stubs(:arping).with('-D', '-c 32', '-w 5', '-I', 'eth1', '10.99.1.4').raises(Exception, """
ARPING 10.99.1.4 from 0.0.0.0 eth1
Unicast reply from 10.99.1.4 [00:1C:42:99:06:98]  1.292ms
Sent 1 probes (1 broadcast(s))
Received 1 response(s)
      """)
      provider.expects(:warn).with { |arg| arg =~ /IP\s+duplication/ }
      provider.create
      provider.flush
    end

    it "Arping execution error while assigning IP address to the NIC" do
      provider.class.stubs(:arping).with('-D', '-c 32', '-w 5', '-I', 'eth1', '10.99.1.4').raises(Puppet::ExecutionFailure, '')
      provider.create
      expect{provider.flush}.to raise_error(Puppet::ExecutionFailure)
    end

  end

end