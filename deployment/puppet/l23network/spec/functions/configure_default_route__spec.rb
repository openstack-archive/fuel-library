require 'spec_helper'

describe 'configure_default_route' do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  let(:subject) do
    Puppet::Parser::Functions.function(:configure_default_route)
  end

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

  it 'should exist' do
    expect(subject).to eq 'function_configure_default_route'
  end

  it 'should expect 3 arguments' do
    expect { scope.function_configure_default_route [] }.to raise_error
  end

  it 'should configure default the default route if gateway ip is equal to master_ip' do
    arguments = [network_scheme, master_ip, management_vrouter_vip]
    ifconfig = scope.function_configure_default_route arguments
    expect(ifconfig['br-mgmt']).to eq({
                                     "ipaddr"=>["192.168.0.5/24"],
                                       "vendor_specific"=>{
                                           "vlans"=>"101",
                                           "phy_interfaces"=>["eth0"]
                                       },
                                       "gateway"=>"192.168.0.2"
                                   })
    expect(ifconfig['br-fw-admin']).to eq({
                                         "ipaddr"=>["10.20.0.6/24"]
                                       })

  end

  it 'should not configure interfaces if master_ip is not equal to the gateway' do
    arguments = [network_scheme, '10.20.0.3', management_vrouter_vip]
    ifconfig = scope.function_configure_default_route arguments
    expect(ifconfig).to eq({})
  end

end
