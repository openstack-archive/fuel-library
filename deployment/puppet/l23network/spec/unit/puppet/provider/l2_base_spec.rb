require 'spec_helper'

require File.join File.dirname(__FILE__), '../../../../lib/puppet/provider/l2_base.rb'

provider_class = Puppet::Provider::L2_base

describe provider_class do
  let(:subject) { provider_class }

  let(:ovs_vsctl_show) do
    out = <<-eos
750f5911-629e-409a-a109-f5315c72467a
    Bridge br-prv
        Port phy-br-prv
            Interface phy-br-prv
                type: patch
                options: {peer=int-br-prv}
        Port "p_br-prv-0"
            Interface "p_br-prv-0"
                type: internal
        Port br-prv
            Interface br-prv
                type: internal
    Bridge br-int
        fail_mode: secure
        Port int-br-prv
            Interface int-br-prv
                type: patch
                options: {peer=phy-br-prv}
        Port br-int
            Interface br-int
                type: internal
    ovs_version: "2.3.1"
    eos
    out.split("\n").map { |line| line.chomp }
  end

  let(:ovs_vsctl_list_bridge) do
    out = <<-eos
_uuid               : b47efcd9-7b7f-4a11-81ac-6ae6f6ed585d
controller          : []
datapath_id         : "0000dafc7eb4114a"
datapath_type       : ""
external_ids        : {bridge-id=br-prv}
fail_mode           : []
flood_vlans         : []
flow_tables         : {}
ipfix               : []
mirrors             : []
name                : br-prv
netflow             : []
other_config        : {}
ports               : [828e11fb-75fc-4250-8961-7e56bc8f3ed4, c9d99e7d-ef0a-435a-92cc-134f9b3cd241, e265fe10-49e0-4945-b6cf-7d8063d79d25]
protocols           : []
sflow               : []
status              : {}
stp_enable          : false

_uuid               : e92f3422-8e1b-452c-866d-a26b50e16814
controller          : []
datapath_id         : "000022342fe92c45"
datapath_type       : ""
external_ids        : {}
fail_mode           : secure
flood_vlans         : []
flow_tables         : {}
ipfix               : []
mirrors             : []
name                : br-int
netflow             : []
other_config        : {}
ports               : [69070e0b-a184-49c1-bd7e-fa179fbd271c, e1fa3bfd-3749-4cf3-b5c3-d0b1730505e4]
protocols           : []
sflow               : []
status              : {}
stp_enable          : false
    eos
    out.split("\n").map { |line| line.chomp }
  end

  let(:ovs_vsctl_list_port) do
    out = <<-eos
uuid               : e265fe10-49e0-4945-b6cf-7d8063d79d25                                                                            [63/1861]
bond_active_slave   : []
bond_downdelay      : 0
bond_fake_iface     : false
bond_mode           : []
bond_updelay        : 0
external_ids        : {}
fake_bridge         : false
interfaces          : [b8cff9cb-db9e-4505-a960-58d0cae7afdb]
lacp                : []
mac                 : []
name                : br-prv
other_config        : {}
qos                 : []
statistics          : {}
status              : {}
tag                 : []
trunks              : []
vlan_mode           : []

_uuid               : c9d99e7d-ef0a-435a-92cc-134f9b3cd241
bond_active_slave   : []
bond_downdelay      : 0
bond_fake_iface     : false
bond_mode           : []
bond_updelay        : 0
external_ids        : {}
fake_bridge         : false
interfaces          : [94ec8b49-558e-43c6-ae1f-397d8831cb0f]
lacp                : []
mac                 : []
name                : "p_br-prv-0"
other_config        : {}
qos                 : []
statistics          : {}
status              : {}
tag                 : []
trunks              : []
    eos
    out.split("\n").map { |line| line.chomp }
  end

  let(:ovs_vsctl_list_interface) do
    out = <<-eos
_uuid               : 37119dad-00fa-41fd-a45a-5639a16954fc                                                                           [126/1825]
admin_state         : up
bfd                 : {}
bfd_status          : {}
cfm_fault           : []
cfm_fault_status    : []
cfm_flap_count      : []
cfm_health          : []
cfm_mpid            : []
cfm_remote_mpids    : []
cfm_remote_opstate  : []
duplex              : []
external_ids        : {}
ifindex             : 0
ingress_policing_burst: 0
ingress_policing_rate: 0
lacp_current        : []
link_resets         : 0
link_speed          : []
link_state          : up
mac                 : []
mac_in_use          : "fa:17:e0:00:74:a8"
mtu                 : []
name                : int-br-prv
ofport              : 1
ofport_request      : []
options             : {peer=phy-br-prv}
other_config        : {}
statistics          : {collisions=0, rx_bytes=24949, rx_crc_err=0, rx_dropped=0, rx_errors=0, rx_frame_err=0, rx_over_err=0, rx_packets=361, tx
_bytes=0, tx_dropped=0, tx_errors=0, tx_packets=0}
status              : {}
type                : patch
    eos
    out.split("\n").map { |line| line.chomp }
  end

  let(:ovs_vsctl_result) do
    {
        :port=>{
            "phy-br-prv"=>{
                :bridge=>"br-prv",
                :port_type=>["jack"],
                :provider=>nil,
                :mtu=>nil
            },
            "p_br-prv-0"=>{
                :bridge=>"br-prv",
                :port_type=>["internal"],
                :vendor_specific=>{
                    :other_config=>{},
                    :status=>{}
                },
                :provider=>nil,
                :mtu=>nil
            },
            "br-prv"=>{
                :bridge=>"br-prv",
                :port_type=>["bridge", "internal"],
                :vendor_specific=>{
                    :other_config=>{},
                    :status=>{}
                },
                :provider=>nil,
                :mtu=>nil
            },
            "int-br-prv"=>{
                :bridge=>"br-int",
                :port_type=>["jack"],
                :provider=>"ovs",
                :mtu=>""
            },
            "br-int"=>{
                :bridge=>"br-int",
                :port_type=>["bridge", "internal"],
                :provider=>nil,
                :mtu=>nil
            }
        },
        :interface=>{
            "phy-br-prv"=>{
                :port=>"phy-br-prv",
                :type=>"patch",
                :options=>{"peer"=>"int-br-prv"}
            },
            "p_br-prv-0"=>{
                :port=>"p_br-prv-0",
                :type=>"internal"
            },
            "br-prv"=>{
                :port=>"br-prv",
                :type=>"internal"
            },
            "int-br-prv"=>{
                :port=>"int-br-prv",
                :mtu=>"",
                :port_type=>["patch"],
                :vendor_specific=>{:status=>{}},
                :provider=>"ovs",
                :type=>"patch",
                :options=>{"peer"=>"phy-br-prv"}},
            "br-int"=>{
                :port=>"br-int",
                :type=>"internal"
            }
        },
        :bridge=>{
            "br-prv"=>{
                :port_type=>["bridge"],
                :br_type=>"ovs",
                :provider=>"ovs",
                :stp=>false,
                :vendor_specific=>{
                    :datapath_type=>"",
                    :external_ids=>{:"bridge-id"=>"br-prv"},
                    :other_config=>{}, :status=>{}
                }
            },
            "br-int"=>{
                :port_type=>["bridge"],
                :br_type=>"ovs",
                :provider=>"ovs",
                :stp=>false,
                :vendor_specific=>{
                    :datapath_type=>"",
                    :external_ids=>{},
                    :other_config=>{},
                    :status=>{}
                }
            }
        },
        :jack=>{}
    }
  end

  let(:get_lnx_bonds_result) do
  {
    "bond0" => {
      :mtu=>:absent,
      :slaves=>[],
      :bond_properties=>{
        :mode=>"balance-rr",
        :miimon=>"0",
        :updelay=>"0",
        :downdelay=>"0"
       },
       :onboot=>false
     }
  }
  end

  before(:each) do
    puppet_debug_override()
    subject.stubs(:ovs_vsctl).with('show').returns ovs_vsctl_show
    subject.stubs(:ovs_vsctl).with(['list', 'Bridge']).returns ovs_vsctl_list_bridge
    subject.stubs(:ovs_vsctl).with(['list', 'Port']).returns ovs_vsctl_list_port
    subject.stubs(:ovs_vsctl).with(['list', 'Interface']).returns ovs_vsctl_list_interface
  end

  it 'should exist' do
    expect(subject.to_s).to eq 'Puppet::Provider::L2_base'
  end

  it 'parses the output of "ovs-vsctl show"' do
    expect(subject.ovs_vsctl_show).to eq ovs_vsctl_result
  end

  it 'parses the sysfs to get_lnx_bonds where is no bonds' do
    subject.stubs(:get_sys_class).with('/sys/class/net/bonding_masters', true).returns([''])
    expect(subject.get_lnx_bonds).to eq Hash[]
  end

  it 'parses the sysfs to get_lnx_bonds' do
    subject.stubs(:get_sys_class).with('/sys/class/net/bonding_masters', true).returns(['bond0'])
    subject.stubs(:get_sys_class).with('/sys/class/net/bond0/bonding/mode').returns('balance-rr')
    subject.stubs(:get_sys_class).with('/sys/class/net/bond0/mtu').returns('1500')
    subject.stubs(:get_sys_class).with('/sys/class/net/bond0/bonding/slaves', true).returns([])
    subject.stubs(:get_sys_class).with('/sys/class/net/bond0/bonding/miimon').returns('0')
    subject.stubs(:get_sys_class).with('/sys/class/net/bond0/bonding/updelay').returns('0')
    subject.stubs(:get_sys_class).with('/sys/class/net/bond0/bonding/downdelay').returns('0')
    subject.stubs(:get_sys_class).with('/sys/class/net/bond0/bonding/mode').returns('balance-rr')
    subject.stubs(:get_sys_class).with('/sys/class/net/bond0/bonding/mode').returns('balance-rr')

    expect(subject.get_lnx_bonds).to eq get_lnx_bonds_result
  end
end
