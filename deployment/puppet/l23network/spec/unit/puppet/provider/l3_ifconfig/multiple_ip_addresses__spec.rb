require 'spec_helper'

describe Puppet::Type.type(:l3_ifconfig).provider(:lnx) do

  let(:resource) {
    Puppet::Type.type(:l3_ifconfig).new(
      :name      => 'eth1',
      :interface => 'eth1',
      :ensure    => :present,
      :ipaddr    => ['192.168.1.1/24','192.168.2.2/25','192.168.3.3/26',],
      :gateway   => :absent,
      :provider  => :lnx
    )
  }

  let(:provider) { resource.provider }

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

    it "no existing IPs on the given NIC, just creating" do
      #provider.expects(:warn).with { |arg| arg =~ /IP\s+duplication/ }.never
      provider.class.expects(:get_if_defroutes_mappings).with().returns({})
      #provider.class.expects(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>[]}})
      provider.class.expects(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>[]}})
      provider.class.instances
      provider.create
      #
      provider.class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.1.1']).returns(true)
      provider.class.expects(:iproute).with(['addr', 'add', '192.168.1.1/24', 'dev', 'eth1'])
      provider.class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.1.1']).returns(true)
      #
      provider.class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.2.2']).returns(true)
      provider.class.expects(:iproute).with(['addr', 'add', '192.168.2.2/25', 'dev', 'eth1'])
      provider.class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.2.2']).returns(true)
      #
      provider.class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
      provider.class.expects(:iproute).with(['addr', 'add', '192.168.3.3/26', 'dev', 'eth1'])
      provider.class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
      #
      provider.class.expects(:iproute).with(['route', 'del', 'default', 'dev', 'eth1']).raises("Non-fatal-Error: Can't flush routes for interface 'eth1': XXX")
      provider.flush
    end

    it "replace part of existing IPs on the the NIC, i.e. modifying" do
      provider.class.stubs(:get_if_defroutes_mappings).with().returns({})
      provider.class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>['1.1.1.1/24', '2.2.2.2/25', '192.168.1.1/24']}})
      #instance.stubs(:old_property_hash).with().returns({ :ipaddr =>['1.1.1.1/24', '2.2.2.2/25', '192.168.1.1/24'] })
      #provider.class.expects(:addr_flush).with('eth1', true)
      #
      provider.class.expects(:iproute).with(['--force', 'addr', 'del', '1.1.1.1/24', 'dev', 'eth1']).returns(true)
      provider.class.expects(:iproute).with(['--force', 'addr', 'del', '2.2.2.2/25', 'dev', 'eth1']).returns(true)
      #
      provider.class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.1.1']).returns(true)
      provider.class.expects(:iproute).with(['addr', 'add', '192.168.1.1/24', 'dev', 'eth1'])
      provider.class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.1.1']).returns(true)
      #
      provider.class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.2.2']).returns(true)
      provider.class.expects(:iproute).with(['addr', 'add', '192.168.2.2/25', 'dev', 'eth1'])
      provider.class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.2.2']).returns(true)
      #
      provider.class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
      provider.class.expects(:iproute).with(['addr', 'add', '192.168.3.3/26', 'dev', 'eth1'])
      provider.class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
      #
      provider.class.expects(:iproute).with(['route', 'del', 'default', 'dev', 'eth1']).raises("Non-fatal-Error: Can't flush routes for interface 'eth1': XXX")
      #provider.create
      resource.expects(:exists?).with().returns(true)
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