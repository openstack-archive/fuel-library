require 'spec_helper'

describe Puppet::Type.type(:l3_ifconfig).provider(:lnx) do

  let(:resource) {
    Puppet::Type.type(:l3_ifconfig).new(
      :name      => 'eth1',
      :interface => 'eth1',
      :ensure    => :present,
      :ipaddr    => ['192.168.1.1/24','192.168.2.2/25','192.168.3.3/26'],
      :gateway   => :absent,
      :provider  => :lnx
    )
  }

  let(:provider_class) {
    Puppet::Type.type(:l3_ifconfig).provider(:lnx)
  }

  let(:provider) {
    prefetched_provider = provider_class.instances.first
    resource.provider = prefetched_provider if prefetched_provider
    resource.provider
  }

  before(:each) do
    puppet_debug_override()
  end

  it "no existing IPs on the given NIC, just creating" do
    #provider.expects(:warn).with { |arg| arg =~ /IP\s+duplication/ }.never
    provider_class.stubs(:get_if_defroutes_mappings).with().returns({})
    provider_class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>[]}})
    #provider.class.instances
    provider.create
    provider_class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.1.1']).returns(true)
    provider_class.expects(:iproute).with(['addr', 'add', '192.168.1.1/24', 'dev', 'eth1'])
    provider_class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.1.1']).returns(true)
    #
    provider_class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.2.2']).returns(true)
    provider_class.expects(:iproute).with(['addr', 'add', '192.168.2.2/25', 'dev', 'eth1'])
    provider_class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.2.2']).returns(true)
    #
    provider_class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
    provider_class.expects(:iproute).with(['addr', 'add', '192.168.3.3/26', 'dev', 'eth1'])
    provider_class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
    #
    provider_class.expects(:iproute).with(['route', 'del', 'default', 'dev', 'eth1']).raises("Non-fatal-Error: Can't flush routes for interface 'eth1': XXX")
    provider.flush
  end

  it "replace part of existing IPs on the the NIC, i.e. modifying" do
    provider_class.stubs(:get_if_defroutes_mappings).with().returns({})
    provider_class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>['1.1.1.1/24', '2.2.2.2/25', '192.168.1.1/24']}})
    provider.ipaddr = provider.resource[:ipaddr]  # emulate puppet works

    # unnided IP addressses should be removed
    provider_class.expects(:iproute).with(['--force', 'addr', 'del', '1.1.1.1/24', 'dev', 'eth1']).returns(true)
    provider_class.expects(:iproute).with(['--force', 'addr', 'del', '2.2.2.2/25', 'dev', 'eth1']).returns(true)
    # required IP addresses should be added
    provider_class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.2.2']).returns(true)
    provider_class.expects(:iproute).with(['addr', 'add', '192.168.2.2/25', 'dev', 'eth1'])
    provider_class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.2.2']).returns(true)
    #
    provider_class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
    provider_class.expects(:iproute).with(['addr', 'add', '192.168.3.3/26', 'dev', 'eth1'])
    provider_class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
    #
    provider.flush
  end

  it "Change netmask(increase and decrese) of two IPs and add one IP on the same NIC" do
    provider_class.stubs(:get_if_defroutes_mappings).with().returns({})
    provider_class.stubs(:get_if_addr_mappings).with().returns({'eth1' => {:ipaddr =>['192.168.2.2/26', '2.2.2.2/25', '192.168.1.1/23']}})
    provider.ipaddr = provider.resource[:ipaddr]  # emulate puppet work
    # not needed IP address should be removed
    provider_class.expects(:iproute).with(['--force', 'addr', 'del', '2.2.2.2/25', 'dev', 'eth1']).returns(true)
    # Change netmask for two IP address
    provider_class.expects(:iproute).with(['addr', 'add', '192.168.1.1/24', 'dev', 'eth1']).returns(true)
    provider_class.expects(:iproute).with(['--force', 'addr', 'del', '192.168.1.1/23', 'dev', 'eth1']).returns(true)
    provider_class.expects(:iproute).with(['addr', 'add', '192.168.2.2/25', 'dev', 'eth1']).returns(true)
    provider_class.expects(:iproute).with(['--force', 'addr', 'del', '192.168.2.2/26', 'dev', 'eth1']).returns(true)
    # required IP address should be added
    provider_class.expects(:arping).with(['-D', '-f', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
    provider_class.expects(:iproute).with(['addr', 'add', '192.168.3.3/26', 'dev', 'eth1'])
    provider_class.expects(:arping).with(['-A', '-c 32', '-w 2', '-I', 'eth1', '192.168.3.3']).returns(true)
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
