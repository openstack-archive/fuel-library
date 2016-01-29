require 'spec_helper'

type_class = Puppet::Type.type(:l2_bridge)
provider_class = type_class.provider(:ovs)

describe provider_class do
  let(:resource) do
    type_class.new(
        :ensure => 'present',
        :use_ovs => true,
        :external_ids => {
            'bridge-id' => 'br-floating',
        },
        :provider => :ovs,
        :name => 'br-floating',
    )
  end

  let(:provider) { resource.provider }

  let(:ovs_vsctl_show) {
    {
        :port => {"phy-br-prv" => {
            :bridge => "br-prv",
            :port_type => ["jack"],
            :vendor_specific => {
                :other_config => {},
                :status => {}
            },
            :provider => "ovs",
            :mtu => ""
        },
                  "p_br-prv-0" => {
                      :bridge => "br-prv",
                      :port_type => ["internal"],
                      :vendor_specific => {
                          :other_config => {},
                          :status => {}
                      },
                      :provider => "ovs",
                      :mtu => "1500"
                  },
                  "br-prv" => {
                      :bridge => "br-prv",
                      :port_type => ["bridge", "internal"],
                      :vendor_specific => {
                          :other_config => {},
                          :status => {}
                      },
                      :provider => "ovs",
                      :mtu => "1500"
                  },
                  "int-br-prv" => {
                      :bridge => "br-int",
                      :port_type => ["jack"],
                      :vendor_specific => {
                          :other_config => {},
                          :status => {}
                      },
                      :provider => "ovs",
                      :mtu => ""
                  },
                  "br-int" => {
                      :bridge => "br-int",
                      :port_type => ["bridge", "internal"],
                      :vendor_specific => {
                          :other_config => {},
                          :status => {}
                      },
                      :provider => "ovs",
                      :mtu => ""
                  }
        },
        :interface => {
            "phy-br-prv" => {
                :port => "phy-br-prv",
                :mtu => "",
                :port_type => ["patch"],
                :vendor_specific => {:status => {}},
                :provider => "ovs",
                :type => "patch",
                :options => {"peer" => "int-br-prv"}},
            "p_br-prv-0" => {
                :port => "p_br-prv-0",
                :mtu => "1500",
                :port_type => ["internal"],
                :vendor_specific => {
                    :status => {:driver_name => "openvswitch"}
                },
                :provider => "ovs",
                :type => "internal"
            },
            "br-prv" => {
                :port => "br-prv",
                :mtu => "1500",
                :port_type => ["internal"],
                :vendor_specific => {
                    :status => {
                        :driver_name => "openvswitch"
                    }
                },
                :provider => "ovs",
                :type => "internal"
            },
            "int-br-prv" => {
                :port => "int-br-prv",
                :mtu => "",
                :port_type => ["patch"],
                :vendor_specific => {:status => {}},
                :provider => "ovs",
                :type => "patch",
                :options => {"peer" => "phy-br-prv"}
            },
            "br-int" => {
                :port => "br-int",
                :mtu => "",
                :port_type => ["internal"],
                :vendor_specific => {:status => {}},
                :provider => "ovs",
                :type => "internal"}
        },
        :bridge => {
            "br-prv" => {
                :port_type => ["bridge"],
                :br_type => "ovs",
                :provider => "ovs",
                :stp => false,
                :vendor_specific => {
                    :datapath_type=>"",
                    :external_ids => {
                        :"bridge-id" => "br-prv"
                    },
                    :other_config => {},
                    :status => {}}},
            "br-dpdk" => {
                :port_type => ["bridge"],
                :br_type => "ovs",
                :provider => "ovs",
                :stp => false,
                :vendor_specific => {
                    :datapath_type=>"netdev",
                    :external_ids => {
                        :"bridge-id" => "br-dpdk"
                    },
                    :other_config => {},
                    :status => {}}},
            "br-int" => {
                :port_type => ["bridge"],
                :br_type => "ovs",
                :provider => "ovs",
                :stp => false,
                :vendor_specific => {
                    :datapath_type=>"",
                    :external_ids => {},
                    :other_config => {},
                    :status => {}
                }
            }
        },
        :jack => {}
    }
  }

  let(:bridge_instances) {
      [
          {
              :ensure=>:present,
              :name=>"br-prv",
              :vendor_specific=>{
                  :datapath_type=>"",
                  :external_ids=>{
                      :"bridge-id"=>"br-prv"
                  },
                  :other_config=>{},
                  :status=>{}
              },
              :port_type=>"ovs:bridge",
              :br_type=>"ovs",
              :provider=>"ovs",
              :stp=>false
          },
          {
              :ensure=>:present,
              :name=>"br-dpdk",
              :vendor_specific=>{
                  :datapath_type=>"netdev",
                  :external_ids=>{
                      :"bridge-id"=>"br-dpdk"
                  },
                  :other_config=>{},
                  :status=>{}
              },
              :port_type=>"ovs:bridge",
              :br_type=>"ovs",
              :provider=>"ovs",
              :stp=>false
          },
          {
              :ensure=>:present,
              :name=>"br-int",
              :vendor_specific=>{
                  :datapath_type=>"",
                  :external_ids=>{},
                  :other_config=>{},
                  :status=>{}
              },
              :port_type=>"ovs:bridge",
              :br_type=>"ovs",
              :provider=>"ovs",
              :stp=>false
          }
      ]
  }

  before(:each) do
    puppet_debug_override()
  end

  it 'should exists' do
    expect(provider).not_to be_nil
  end

  it 'should generate the array on provider instances' do
    provider_class.stubs(:ovs_vsctl_show).returns ovs_vsctl_show
    instances = provider_class.instances
    expect(instances).to be_a Array
    expect(instances.length).to eq 3
    instances.each do |provider|
      expect(provider).to be_a Puppet::Type::L2_bridge::ProviderOvs
      class << provider
          def property_hash
              @property_hash
          end
      end
    end
    expect(instances.map { |p| p.property_hash }).to eq bridge_instances
  end
end
