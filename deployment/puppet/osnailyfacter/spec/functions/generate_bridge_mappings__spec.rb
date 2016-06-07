require 'puppet'
require 'spec_helper'

describe 'function for formating allocation pools for neutron subnet resource' do

  def setup_scope
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("floppy", :environment => 'production'))
    @scope = Puppet::Parser::Scope.new(@compiler)
    @topscope = @topscope
    @scope.parent = @topscope
    Puppet::Parser::Functions.function(:generate_bridge_mappings)
  end

  describe 'basic tests' do

    before :each do
      setup_scope
      puppet_debug_override
    end

    let :network_scheme do
{"transformations"=>
  [{"action"=>"add-br", "name"=>"br-fw-admin"},
   {"action"=>"add-br", "name"=>"br-mgmt"},
   {"action"=>"add-br", "name"=>"br-storage"},
   {"action"=>"add-br", "name"=>"br-ex"},
   {"action"=>"add-br", "name"=>"br-floating", "provider"=>"ovs"},
   {"action"=>"add-patch",
    "bridges"=>["br-floating", "br-ex"],
    "provider"=>"ovs",
    "mtu"=>65000},
   {"action"=>"add-br", "name"=>"br-prv", "provider"=>"ovs"},
   {"action"=>"add-br", "name"=>"br-aux"},
   {"action"=>"add-patch",
    "bridges"=>["br-prv", "br-aux"],
    "provider"=>"ovs",
    "mtu"=>65000},
   {"action"=>"add-port", "bridge"=>"br-fw-admin", "name"=>"eth0"},
   {"action"=>"add-port", "bridge"=>"br-ex", "name"=>"eth1"},
   {"bridge"=>"br-aux",
    "name"=>"bond0",
    "interfaces"=>["eth2", "eth3"],
    "bond_properties"=>{"mode"=>"active-backup"},
    "interface_properties"=>{"vendor_specific"=>{"disable_offloading"=>true}},
    "action"=>"add-bond"},
   {"action"=>"add-port", "bridge"=>"br-mgmt", "name"=>"bond0.101"},
   {"action"=>"add-port", "bridge"=>"br-storage", "name"=>"bond0.102"}],
 "roles"=>
  {"keystone/api"=>"br-mgmt",
   "neutron/api"=>"br-mgmt",
   "mgmt/database"=>"br-mgmt",
   "sahara/api"=>"br-mgmt",
   "heat/api"=>"br-mgmt",
   "ceilometer/api"=>"br-mgmt",
   "ex"=>"br-ex",
   "ceph/public"=>"br-mgmt",
   "mgmt/messaging"=>"br-mgmt",
   "management"=>"br-mgmt",
   "swift/api"=>"br-mgmt",
   "storage"=>"br-storage",
   "mgmt/corosync"=>"br-mgmt",
   "cinder/api"=>"br-mgmt",
   "public/vip"=>"br-ex",
   "swift/replication"=>"br-storage",
   "ceph/radosgw"=>"br-ex",
   "admin/pxe"=>"br-fw-admin",
   "mongo/db"=>"br-mgmt",
   "neutron/private"=>"br-prv",
   "neutron/floating"=>"br-floating",
   "fw-admin"=>"br-fw-admin",
   "glance/api"=>"br-mgmt",
   "mgmt/vip"=>"br-mgmt",
   "murano/api"=>"br-mgmt",
   "nova/api"=>"br-mgmt",
   "horizon"=>"br-mgmt",
   "nova/migration"=>"br-mgmt",
   "mgmt/memcache"=>"br-mgmt",
   "cinder/iscsi"=>"br-storage",
   "ceph/replication"=>"br-storage"},
 "interfaces"=>
  {"eth5"=>
    {"vendor_specific"=>{"driver"=>"e1000", "bus_info"=>"0000:00:08.0"}},
   "eth4"=>
    {"vendor_specific"=>{"driver"=>"e1000", "bus_info"=>"0000:00:07.0"}},
   "eth3"=>
    {"vendor_specific"=>{"driver"=>"e1000", "bus_info"=>"0000:00:06.0"}},
   "eth2"=>
    {"vendor_specific"=>{"driver"=>"e1000", "bus_info"=>"0000:00:05.0"}},
   "eth1"=>
    {"vendor_specific"=>{"driver"=>"e1000", "bus_info"=>"0000:00:04.0"}},
   "eth0"=>
    {"vendor_specific"=>{"driver"=>"e1000", "bus_info"=>"0000:00:03.0"}}},
 "version"=>"1.1",
 "provider"=>"lnx",
 "endpoints"=>
  {"br-fw-admin"=>{"IP"=>["10.109.0.4/24"]},
   "br-prv"=>{"IP"=>"none"},
   "br-floating"=>{"IP"=>"none"},
   "br-storage"=>{"IP"=>["192.168.1.1/24"]},
   "br-mgmt"=>{"IP"=>["192.168.0.4/24"]},
   "br-ex"=>{"IP"=>["10.109.1.4/24"], "gateway"=>"10.109.1.1"}}
    }
    end

    let :neutron_config do
       {"default_floating_net"=>"admin_floating_net",
         "database"=>{"passwd"=>"2eaczPxjQNxkR6qik3sZlsaW"},
         "default_private_net"=>"admin_internal_net",
         "keystone"=>{"admin_password"=>"EanTYjYlXqzATHAriBPkllal"},
         "L3"=>{"use_namespaces"=>true},
         "L2"=>{"phys_nets"=>{"physnet1"=>{"bridge"=>"br-prv", "vlan_range"=>"1000:1030"},
                              "physnet2"=>{"bridge"=>"br-floating", "vlan_range"=>nil}},
                "base_mac"=>"fa:16:3e:00:00:00",
                "segmentation_type"=>"vlan"},
         "predefined_networks"=>{
            "admin_floating_net"=>{
               "shared"=>false,
               "L2"=>{"network_type"=>"local",
                      "router_ext"=>true,
                      "physnet"=>'physnet2',
                      "segment_id"=>nil},
               "L3"=>{"nameservers"=>[],
                      "subnet"=>"10.109.1.0/24",
                      "floating"=>["10.109.1.130:10.109.1.254"],
                      "gateway"=>"10.109.1.1",
                      "enable_dhcp"=>false},
                      "tenant"=>"admin"},
            "admin_internal_net"=>{
               "shared"=>false,
               "L2"=>{"network_type"=>"vlan",
                      "router_ext"=>false,
                      "physnet"=>"physnet1",
                      "segment_id"=>nil},
               "L3"=>{"nameservers"=>["8.8.4.4", "8.8.8.8"],
                      "subnet"=>"192.168.111.0/24",
                      "floating"=>nil,
                      "gateway"=>"192.168.111.1",
                      "enable_dhcp"=>true},
               "tenant"=>"admin"}},
         "metadata"=>{"metadata_proxy_shared_secret"=>"uLLpFlxwX848GYnTUse2PjMp"}
      }
    end

    it "should exist" do
      expect(Puppet::Parser::Functions.function(:generate_bridge_mappings)).to eq "function_generate_bridge_mappings"
    end

    it 'error if no arguments' do
      expect(lambda { @scope.function_generate_bridge_mappings([]) }).to raise_error(ArgumentError, 'generate_bridge_mappings(): wrong number of arguments (0; must be 3)')
    end

    it 'should require one argument' do
      expect(lambda { @scope.function_generate_bridge_mappings(['foo', 'wee', 'ee', 'rr']) }).to raise_error(ArgumentError, 'generate_bridge_mappings(): wrong number of arguments (4; must be 3)')
    end


    it 'should be able to return floating and tenant nets to bridge map' do
      expect(@scope.function_generate_bridge_mappings([neutron_config, network_scheme, { 'do_floating' => true, 'do_tenant' => true, 'do_provider' => false }])).to eq(["physnet1:br-prv", "physnet2:br-floating"])
    end

    it 'should be able to return only floating nets to bridge map' do
      expect(@scope.function_generate_bridge_mappings([neutron_config, network_scheme, { 'do_floating' => true, 'do_tenant' => false, 'do_provider' => false }])).to eq(["physnet2:br-floating"])
    end

    it 'should be able to return only tenant nets to bridge map' do
      expect(@scope.function_generate_bridge_mappings([neutron_config, network_scheme, { 'do_floating' => false, 'do_tenant' => true, 'do_provider' => false }])).to eq(["physnet1:br-prv"])
    end

  end
end
