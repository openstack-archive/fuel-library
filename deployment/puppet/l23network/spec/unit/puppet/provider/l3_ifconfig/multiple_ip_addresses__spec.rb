require 'spec_helper'

describe Puppet::Type.type(:l3_ifconfig).provider(:lnx) do

  let(:resource) {
    Puppet::Type.type(:l3_ifconfig).new(
      :name      => 'eth1',
      :interface => 'eth1',
      :ensure    => :present,
      :ipaddr    => 'none',
      :gateway   => :absent,
      :provider  => :lnx
    )
  }

  let(:provider) { resource.provider }
  #let(:instance) { provider.class.instances }

  describe "l3_ifconfig " do
    before(:each) do
      if ENV['SPEC_PUPPET_DEBUG']
        Puppet::Util::Log.level = :debug
        Puppet::Util::Log.newdestination(:console)
      end
      #provider.class.stubs(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '10.99.1.4']).returns(true)
      #provider.class.stubs(:iproute)
      #provider.class.stubs(:iproute).with(['route', 'del', 'default', 'dev', 'eth1']).raises(Puppet::ExecutionFailure)
    end

    it "no existing IPs to remove for the the NIC" do
      #provider.class.stubs(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '10.99.1.4']).returns(true)
      #provider.expects(:warn).with { |arg| arg =~ /IP\s+duplication/ }.never
      provider.class.stubs(:get_if_defroutes_mappings).with().returns({})
      provider.class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>[]}})
      provider.class.instances
      provider.create
      provider.class.stubs(:addr_flush).with('eth1', true)
      provider.flush
    end

    it "remove all existing IPs from the the NIC" do
      provider.class.stubs(:get_if_defroutes_mappings).with().returns({})
      provider.class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>['1.1.1.1/24', '2.2.2.2/25']}})
      provider.class.instances
      provider.create
      provider.class.stubs(:addr_flush).with('eth1', true)
      provider.flush
    end

#     it "Assign duplication IP address to the NIC" do
#       provider.class.stubs(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '10.99.1.4']).raises(Exception, """
# ARPING 10.99.1.4 from 0.0.0.0 eth1
# Unicast reply from 10.99.1.4 [00:1C:42:99:06:98]  1.292ms
# Sent 1 probes (1 broadcast(s))
# Received 1 response(s)
#       """)
#       provider.expects(:warn).with { |arg| arg =~ /IP\s+duplication/ }
#       provider.create
#       provider.flush
#     end

#     it "Arping execution error while assigning IP address to the NIC" do
#       provider.class.stubs(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '10.99.1.4']).raises(Puppet::ExecutionFailure, '')
#       provider.create
#       expect{provider.flush}.to raise_error(Puppet::ExecutionFailure)
#     end

  end

end