require 'puppet'
require 'spec_helper'

describe 'function for neutron network and subnetwork configuration ' do

  def setup_scope
    @compiler = Puppet::Parser::Compiler.new(Puppet::Node.new("floppy", :environment => 'production'))
    if Puppet.version =~ /^3\./
      @scope = Puppet::Parser::Scope.new(@compiler)
    else
      @scope = Puppet::Parser::Scope.new(:compiler => @compiler)
    end
    @topscope = @topscope
    @scope.parent = @topscope
    Puppet::Parser::Functions.function(:create_network)
  end

  let(:network_data) do
    { "shared"=>false,
      "L2"=>{"network_type"=>"local",
             "router_ext"=>true,
             "physnet"=>nil,
             "segment_id"=>nil},
      "L3"=>{"nameservers"=>[],
             "subnet"=>"10.109.1.0/24",
             "floating"=>["10.109.1.151:10.109.1.254", "10.109.1.130:10.109.1.150"],
             "gateway"=>"10.109.1.1",
             "enable_dhcp"=>false},
       "tenant"=>"admin"
    }
  end

  let(:network_name) { 'net04_ext' }

  describe 'basic tests' do

    before :each do
      setup_scope
      puppet_debug_override
    end

    it "should exist" do
      Puppet::Parser::Functions.function(:create_network).should == "function_create_network"
    end
    it 'should require three arguments' do
      lambda { @scope.function_create_network(['foo', 'wee']) }.should raise_error(ArgumentError, 'create_network(): wrong number of arguments (2; must be 3)')
    end
    it 'should require network data is hash' do
      lambda { @scope.function_create_network(['foo', 'wee', 'dd']) }.should raise_error(ArgumentError, 'create_network(): network_data is not hash!')
    end
  end

  describe 'Creating neutron resources' do
    before :each do
      Puppet[:code]=
'
class t {}
notify{test:}
'
      setup_scope
      puppet_debug_override
    end

    let (:type) {'vlan'}

    let (:seg_id_range) {['300', '500']}

    it 'should be able to add neutron_network resource' do
      @scope.function_create_network([ network_name, network_data, type, seg_id_range])
      @compiler.catalog.resource('neutron_network', network_name)['ensure'].should == 'present'
      @compiler.catalog.resource('neutron_network', network_name)['tenant_name'].should == 'admin'
      @compiler.catalog.resource('neutron_network', network_name)['provider_physical_network'].should == false
      @compiler.catalog.resource('neutron_network', network_name)['provider_segmentation_id'].should == '300'
      @compiler.catalog.resource('neutron_network', network_name)['provider_network_type'].should == type
      @compiler.catalog.resource('neutron_network', network_name)['shared'].should == false
      @compiler.catalog.resource('neutron_network', network_name)['router_external'].should == true
    end

    it 'should be able to add neutron_subnet resource' do
      @scope.function_create_network([ network_name, network_data, 'vlan'])
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['ensure'].should == 'present'
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['cidr'].should == '10.109.1.0/24'
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['network_name'].should == 'net04_ext'
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['tenant_name'].should == 'admin'
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['gateway_ip'].should == '10.109.1.1'
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['enable_dhcp'].should == false
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['dns_nameserv'].should == nil
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['allocation_pools'].should == ['start=10.109.1.151,end=10.109.1.254', 'start=10.109.1.130,end=10.109.1.150']
    end
  end

  describe 'Creating neutron resources without segmentation id range' do

  let(:network_data) do
    { "shared"=>false,
      "L2"=>{"network_type"=>"local",
             "router_ext"=>true,
             "physnet"=>nil,
             "segment_id"=>nil},
      "L3"=>{"nameservers"=>[],
             "subnet"=>"10.109.1.0/24",
             "floating"=>["10.109.1.151:10.109.1.254", "10.109.1.130:10.109.1.150"],
             "gateway"=>"10.109.1.1",
             "enable_dhcp"=>false},
       "tenant"=>"admin"
    }
  end

  before :each do
      Puppet[:code]=
'
class t {}
notify{test:}
'
      setup_scope
      puppet_debug_override
    end

    let (:type) {'vlan'}

    it 'should be able to add neutron_network resource without provided segmentation id range' do
      @scope.function_create_network([ network_name, network_data, type])
      @compiler.catalog.resource('neutron_network', network_name)['ensure'].should == 'present'
      @compiler.catalog.resource('neutron_network', network_name)['provider_segmentation_id'].should == 1
    end

  end

  describe 'Creating neutron resources (old data structure)' do

    let(:network_data) do
      { "shared"=>false,
        "L2"=>{"network_type"=>"local",
               "router_ext"=>true,
               "physnet"=>nil},
        "L3"=>{"nameservers"=>[],
               "subnet"=>"10.109.1.0/24",
               "floating"=>"10.109.1.151:10.109.1.254",
               "gateway"=>"10.109.1.1",
               "enable_dhcp"=>false},
         "tenant"=>"admin"
      }
    end

    let (:type) {'vlan'}

    before :each do
      Puppet[:code]=
'
class t {}
notify{test:}
'
      setup_scope
      puppet_debug_override
    end

    it 'should be able to add neutron_network resource fall back' do
      @scope.function_create_network([ network_name, network_data, type])
      @compiler.catalog.resource('neutron_network', network_name)['ensure'].should == 'present'
      @compiler.catalog.resource('neutron_network', network_name)['provider_network_type'].should == type
    end
 end

  describe 'Creating neutron resources (old data structure)' do

    let(:network_data) do
    { "shared"=>false,
      "L2"=>{"network_type"=>"local",
             "router_ext"=>true,
             "physnet"=>nil,
             "segment_id"=>nil},
      "L3"=>{"nameservers"=>[],
             "subnet"=>"10.109.1.0/24",
             "floating"=>"10.109.1.154:10.109.1.250",
             "gateway"=>"10.109.1.1",
             "enable_dhcp"=>false},
       "tenant"=>"admin"
    }
  end

  let(:network_name) { 'net04_ext' }

    before :each do
      Puppet[:code]=
'
class t {}
notify{test:}
'
      setup_scope
      puppet_debug_override
    end

    it 'should be able to add neutron_subnet resource' do
      @scope.function_create_network([ network_name, network_data, 'vlan'])
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['ensure'].should == 'present'
      @compiler.catalog.resource('neutron_subnet', "#{network_name}__subnet")['allocation_pools'].should == ['start=10.109.1.154,end=10.109.1.250']
    end
  end

end
