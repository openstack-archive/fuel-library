require 'spec_helper'

describe 'configure_default_route' do

  let(:network_scheme) do
    {:provider => "lnx",
     :transformations =>
         [{:action => "add-br", :name => "br-fw-admin"},
          {:action => "add-br", :name => "br-mgmt"},
          {:action => "add-br", :name => "br-storage"},
          {:action => "add-br", :provider => "ovs", :name => "br-prv"},
          {:action => "add-patch",
           :provider => "ovs",
           :bridges => ["br-prv", "br-fw-admin"]},
          {:action => "add-port", :bridge => "br-fw-admin", :name => "eth0"},
          {:action => "add-port", :bridge => "br-storage", :name => "eth0.102"},
          {:action => "add-port", :bridge => "br-mgmt", :name => "eth0.101"}],
     :roles =>
         {:management => "br-mgmt",
          :"fw-admin" => "br-fw-admin",
          :storage => "br-storage",
          :"neutron/private" => "br-prv"},
     :endpoints =>
         {:"br-mgmt" =>
              {:IP => ["192.168.0.5/24"],
               :vendor_specific => {:vlans => 101, :phy_interfaces => ["eth0"]}},
          :"br-prv" =>
              {:IP => nil,
               :vendor_specific => {:vlans => "1000:1030", :phy_interfaces => ["eth0"]}},
          :"br-fw-admin" => {:IP => ["10.20.0.6/24"], :gateway => "10.20.0.2",},
          :"br-storage" =>
              {:IP => ["192.168.1.3/24"],
               :vendor_specific => {:vlans => 102, :phy_interfaces => ["eth0"]}}},
     :version => "1.1",
     :interfaces =>
         {:eth1 => {:vendor_specific => {:driver => "e1000", :bus_info => "0000:00:07.0"}},
          :eth0 => {:vendor_specific => {:driver => "e1000", :bus_info => "0000:00:03.0"}},
          :eth2 => {:vendor_specific => {:driver => "e1000", :bus_info => "0000:00:08.0"}}}}
  end

  let(:master_ip) { '10.20.0.2' }

  let(:management_vrouter_vip) { '192.168.0.2' }

  let(:management_int) { 'management' }
  let(:fw_admin_int) { 'fw-admin' }

  before(:each) do
    puppet_debug_override
  end

  it 'should exist' do
    is_expected.not_to be_nil
  end

  it 'should expect 4 arguments' do
    is_expected.to run.with_params().and_raise_error(Puppet::Error)
  end

  it 'should configure default gateway to vrouter ip' do
    arguments = [network_scheme, management_vrouter_vip, fw_admin_int, management_int]
    ifconfig = scope.function_configure_default_route arguments
     expect(ifconfig[:endpoints][:'br-mgmt'][:gateway]).to eq(management_vrouter_vip)
     expect(ifconfig[:endpoints][:'br-fw-admin'][:gateway]).to eq(nil)
  end

  let(:network_scheme_n) do
    {:provider => "lnx",
     :transformations =>
         [{:action => "add-br", :name => "br-fw-admin"},
          {:action => "add-br", :name => "br-mgmt"},
          {:action => "add-br", :name => "br-storage"},
          {:action => "add-br", :provider => "ovs", :name => "br-prv"},
          {:action => "add-patch",
           :provider => "ovs",
           :bridges => ["br-prv", "br-fw-admin"]},
          {:action => "add-port", :bridge => "br-fw-admin", :name => "eth0"},
          {:action => "add-port", :bridge => "br-storage", :name => "eth0.102"},
          {:action => "add-port", :bridge => "br-mgmt", :name => "eth0.101"}],
     :roles =>
         {:management => "br-mgmt",
          :"fw-admin" => "br-fw-admin",
          :storage => "br-storage",
          :"neutron/private" => "br-prv"},
     :endpoints =>
         {:"br-mgmt" =>
              {:IP => ["192.168.0.5/24"],
               :vendor_specific => {:vlans => 101, :phy_interfaces => ["eth0"]}},
          :"br-prv" =>
              {:IP => nil,
               :vendor_specific => {:vlans => "1000:1030", :phy_interfaces => ["eth0"]}},
          :"br-fw-admin" => {:IP => ["10.20.0.6/24"],},
          :"br-storage" =>
              {:IP => ["192.168.1.3/24"],
               :vendor_specific => {:vlans => 102, :phy_interfaces => ["eth0"]}}},
     :version => "1.1",
     :interfaces =>
         {:eth1 => {:vendor_specific => {:driver => "e1000", :bus_info => "0000:00:07.0"}},
          :eth0 => {:vendor_specific => {:driver => "e1000", :bus_info => "0000:00:03.0"}},
          :eth2 => {:vendor_specific => {:driver => "e1000", :bus_info => "0000:00:08.0"}}}}
  end


  it 'should not reconfigure default gateway' do
    arguments = [network_scheme_n, management_vrouter_vip, 'fw-admin', 'management']
    ifconfig = scope.function_configure_default_route arguments
    expect(ifconfig).to eq({})
  end

  let(:network_scheme_one_interface) do
    {:provider => "lnx",
     :transformations =>
         [{:action => "add-br", :name => "br-fw-admin"},
          {:action => "add-port", :bridge => "br-fw-admin", :name => "eth0"},
         ],
     :roles =>
         {:management => "br-fw-admin",
          :"fw-admin" => "br-fw-admin",
          :"neutron/private" => "br-prv"},
     :endpoints =>
         {:"br-fw-admin" => {:IP => ["10.20.0.6/24"], :gateway => "10.20.0.2",},},
     :version => "1.1",
     :interfaces =>
         {:eth0 => {:vendor_specific => {:driver => "e1000", :bus_info => "0000:00:03.0"}},}}
  end

  let(:management_vrouter_vip_oi) { '10.20.0.3' }
  let(:management_int_oi) { 'management' }
  let(:fw_admin_int_oi) { 'fw-admin' }

  it 'should configure default gateway to vrouter ip (one interface)' do
    arguments = [network_scheme_one_interface, management_vrouter_vip_oi, fw_admin_int_oi, management_int_oi]
    ifconfig = scope.function_configure_default_route arguments
    expect(ifconfig[:endpoints][:'br-fw-admin'][:gateway]).to eq(management_vrouter_vip_oi)
  end

end
