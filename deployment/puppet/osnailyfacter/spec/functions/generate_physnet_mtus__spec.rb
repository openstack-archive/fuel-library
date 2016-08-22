require 'puppet'
require 'yaml'
require 'spec_helper'

describe 'generate_physnet_mtus' do

  describe 'basic tests' do

    before :each do
      puppet_debug_override
    end

    let :network_scheme do
      YAML.load('''
        version: "1.1"
        provider: lnx
        interfaces: {}
        transformations:
          - action: add-br
            name: br-fw-admin
          - action: add-br
            name: br-mgmt
          - action: add-br
            name: br-storage
          - action: add-br
            name: br-ex
          - action: add-br
            name: br-floating
            provider: ovs
          - action: add-patch
            bridges:
              - br-floating
              - br-ex
            provider: ovs
            mtu: 65000
          - action: add-br
            name: br-prv
            provider: ovs
          - action: add-br
            name: br-aux
          - action: add-patch
            bridges:
              - br-prv
              - br-aux
            provider: ovs
            mtu: 65000
          - action: add-port
            bridge: br-fw-admin
            name: eth0
          - action: add-port
            bridge: br-ex
            name: eth1
          - bridge: br-aux
            mtu: 35000
            name: bond0
            interfaces:
              - eth2
              - eth3
            bond_properties:
              mode: active-backup
            interface_properties:
              vendor_specific:
                disable_offloading: true
            action: add-bond
          - action: add-port
            bridge: br-mgmt
            name: bond0.101
          - action: add-port
            bridge: br-storage
            name: bond0.102
        roles: {}
        endpoints: {}
      ''')
    end
    let :network_scheme_just_port do
      YAML.load('''
        version: "1.1"
        provider: lnx
        interfaces: {}
        transformations:
          - action: add-br
            name: br-fw-admin
          - action: add-br
            name: br-mgmt
          - action: add-br
            name: br-storage
          - action: add-br
            name: br-floating
            provider: ovs
          - action: add-br
            name: br-prv
            provider: ovs
          - action: add-br
            name: br-aux
          - action: add-patch
            bridges:
              - br-prv
              - br-aux
            provider: ovs
            mtu: 65000
          - action: add-port
            bridge: br-fw-admin
            name: eth0
          - action: add-port
            bridge: br-floating
            name: eth1
            mtu: 2000
            provider: ovs
          - bridge: br-aux
            mtu: 35000
            name: bond0
            interfaces:
              - eth2
              - eth3
            bond_properties:
              mode: active-backup
            interface_properties:
              vendor_specific:
                disable_offloading: true
            action: add-bond
          - action: add-port
            bridge: br-mgmt
            name: bond0.101
          - action: add-port
            bridge: br-storage
            name: bond0.102
        roles: {}
        endpoints: {}
      ''')
    end

    let :network_scheme_mtu_on_bond do
      YAML.load('''
        version: "1.1"
        provider: lnx
        interfaces: {}
        transformations:
          - action: add-br
            name: br-fw-admin
          - action: add-br
            name: br-mgmt
          - action: add-br
            name: br-storage
          - action: add-br
            name: br-ex
          - action: add-br
            name: br-floating
            provider: ovs
          - action: add-patch
            bridges:
              - br-floating
              - br-ex
            provider: ovs
            mtu: 1300
          - action: add-br
            name: br-prv
            provider: ovs
          - action: add-br
            name: br-aux
          - action: add-patch
            bridges:
              - br-prv
              - br-aux
            provider: ovs
          - action: add-port
            bridge: br-fw-admin
            name: eth0
          - action: add-port
            name: eth0.55
          - action: add-port
            bridge: br-ex
            name: eth1
            mtu: 1340
          - bridge: br-aux
            mtu: 35000
            name: bond0
            interfaces:
              - eth2
              - eth3
            bond_properties:
              mode: active-backup
            interface_properties:
              vendor_specific:
                disable_offloading: true
            action: add-bond
          - action: add-port
            bridge: br-mgmt
            name: bond0.101
          - action: add-port
            bridge: br-storage
            name: bond0.102
        roles: {}
        endpoints: {}
      ''')
    end

    let :network_scheme_mtu_on_port do
      YAML.load('''
        version: "1.1"
        provider: lnx
        interfaces: {}
        transformations:
          - action: add-br
            name: br-fw-admin
          - action: add-br
            name: br-mgmt
          - action: add-br
            name: br-storage
          - action: add-br
            name: br-ex
          - action: add-br
            name: br-floating
            provider: ovs
          - action: add-patch
            bridges:
              - br-floating
              - br-ex
            provider: ovs
          - action: add-br
            name: br-prv
            provider: ovs
          - action: add-br
            name: br-aux
          - action: add-patch
            bridges:
              - br-prv
              - br-aux
            provider: ovs
          - action: add-port
            bridge: br-fw-admin
            name: eth0
          - action: add-port
            bridge: br-ex
            name: eth1
            mtu: 1800
          - bridge: br-aux
            mtu: 35000
            name: bond0
            interfaces:
              - eth2
              - eth3
            bond_properties:
              mode: active-backup
            interface_properties:
              vendor_specific:
                disable_offloading: true
            action: add-bond
          - action: add-port
            bridge: br-mgmt
            name: bond0.101
          - action: add-port
            bridge: br-storage
            name: bond0.102
        roles: {}
        endpoints: {}
      ''')
    end

    let :network_scheme_mtu_on_port_long_chain do
      YAML.load('''
        version: "1.1"
        provider: lnx
        interfaces: {}
        transformations:
          - action: add-br
            name: br-aux1
          - action: add-br
            name: br-aux2
          - action: add-patch
            bridges:
              - br-aux1
              - br-aux2
          - action: add-br
            name: br-prv
            provider: ovs
          - action: add-patch
            bridges:
              - br-prv
              - br-aux2
            provider: ovs
          - action: add-bond
            bridge: br-aux1
            name: bond0
            mtu: 35000
            interfaces:
              - eth2
              - eth3
            bond_properties:
              mode: active-backup
            interface_properties:
              vendor_specific:
                disable_offloading: true
        roles: {}
        endpoints: {}
      ''')
    end

    let :network_scheme_mtu_on_interfaces do
      YAML.load('''
        version: "1.1"
        provider: lnx
        interfaces:
          eth1:
            mtu: 4000
            vendor_specific:
              comment: for floating
          eth2:
            mtu: 9000
            vendor_specific:
              comment: for tenant networks
        transformations:
          - action: add-br
            name: br-ex
          - action: add-br
            name: br-floating
            provider: ovs
          - action: add-patch
            bridges:
              - br-floating
              - br-ex
            provider: ovs
          - action: add-br
            name: br-prv
            provider: ovs
          - action: add-br
            name: br-aux
          - action: add-patch
            bridges:
              - br-prv
              - br-aux
            provider: ovs
          - action: add-port
            bridge: br-ex
            name: eth1
          - action: add-port
            bridge: br-aux
            name: eth2
        roles: {}
        endpoints: {}
      ''')
    end

    let :neutron_config do
      YAML.load('''
        default_floating_net: admin_floating_net
        database:
          passwd: 2eaczPxjQNxkR6qik3sZlsaW
        default_private_net: admin_internal_net
        keystone:
          admin_password: EanTYjYlXqzATHAriBPkllal
        L3:
          use_namespaces: true
        L2:
          phys_nets:
            physnet1:
              bridge: br-prv
              vlan_range: 1000:1030
            physnet2:
              bridge: br-floating
              vlan_range:
          base_mac: fa:16:3e:00:00:00
          segmentation_type: vlan
        predefined_networks:
          admin_floating_net:
            shared: false
            L2:
              network_type: local
              router_ext: true
              physnet: physnet2
              segment_id:
            L3:
              nameservers: []
              subnet: 10.109.1.0/24
              floating:
                - 10.109.1.130:10.109.1.254
              gateway: 10.109.1.1
              enable_dhcp: false
            tenant: admin
          admin_internal_net:
            shared: false
            L2:
              network_type: vlan
              router_ext: false
              physnet: physnet1
              segment_id:
            L3:
              nameservers:
                - 8.8.4.4
                - 8.8.8.8
              subnet: 192.168.111.0/24
              floating:
              gateway: 192.168.111.1
              enable_dhcp: true
            tenant: admin
        metadata:
          metadata_proxy_shared_secret: uLLpFlxwX848GYnTUse2PjMp
      ''')
    end

    it "should exist" do
      is_expected.not_to be_nil
    end

    it 'error if no arguments' do
      is_expected.to run.with_params().and_raise_error(ArgumentError)
    end

    it 'should require one argument' do
      is_expected.to run.with_params('foo', 'wee', 'ee', 'rr').and_raise_error(ArgumentError)
    end

    it 'should be able to return floating and tenant nets to mtu map' do
      is_expected.to run.with_params(neutron_config, network_scheme, { 'do_floating' => true, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000", "physnet2:1500"])
    end

    it 'should be able to return only tenant nets to mtu map' do
      is_expected.to run.with_params(neutron_config, network_scheme, { 'do_floating' => false, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000"])
    end


    it 'should be able to return only floating nets to mtu map' do
      is_expected.to run.with_params(neutron_config, network_scheme, { 'do_floating' => true, 'do_tenant' => false, 'do_provider' => false }).and_return(["physnet2:1500"])
    end

    it 'should be able to return nothing' do
      is_expected.to run.with_params(neutron_config, network_scheme, { 'do_floating' => false, 'do_tenant' => false, 'do_provider' => false }).and_return([])
    end

    it 'should be able to return with floating nets to mtu map (bond)' do
      is_expected.to run.with_params(neutron_config, network_scheme_mtu_on_bond, { 'do_floating' => true, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000", "physnet2:1340"])
    end

    it 'should be able to return without floating nets to mtu map (bond)' do
      is_expected.to run.with_params(neutron_config, network_scheme_mtu_on_bond, { 'do_floating' => false, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000"])
    end

    it 'should be able to return with floating nets to mtu map (port)' do
      is_expected.to run.with_params(neutron_config, network_scheme_mtu_on_port, { 'do_floating' => true, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000", "physnet2:1800"])
    end

    it 'should be able to return only tenant nets to mtu map (port)' do
      is_expected.to run.with_params(neutron_config, network_scheme_mtu_on_port, { 'do_floating' => false, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000"])
    end

    it 'should be able to return only floating nets to mtu map (port)' do
      is_expected.to run.with_params(neutron_config, network_scheme_mtu_on_port, { 'do_floating' => true, 'do_tenant' => false, 'do_provider' => false }).and_return(["physnet2:1800"])
    end

    it 'should be able to return with floating nets to mtu map (just OVS port)' do
      is_expected.to run.with_params(neutron_config, network_scheme_just_port, { 'do_floating' => true, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000", "physnet2:2000"])
    end

    it 'should be able to return without floating nets to mtu map (just OVS port)' do
      is_expected.to run.with_params(neutron_config, network_scheme_just_port, { 'do_floating' => false, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000"])
    end

    it 'should be able to return tenant nets to mtu map if more than one patchcord used and MTU on bond' do
      is_expected.to run.with_params(neutron_config, network_scheme_mtu_on_port_long_chain, { 'do_floating' => false, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:35000"])
    end

    it 'should be able to return mtu map if MTU described into "interface" section' do
      is_expected.to run.with_params(neutron_config, network_scheme_mtu_on_interfaces, { 'do_floating' => true, 'do_tenant' => true, 'do_provider' => false }).and_return(["physnet1:9000", "physnet2:4000"])
    end

  end
end
