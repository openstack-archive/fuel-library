require 'spec_helper'
require 'yaml'


class NeutronConfig
  def initialize() #init_v)
    @def_config = YAML::load(<<-EOM)
network_scheme:
  provider: ovs
  version: "1.0"
  transformations:
  - name: br-eth0
    action: add-br
  - name: eth0
    action: add-port
    bridge: br-eth0
  - name: br-eth1
    action: add-br
  - name: eth1
    action: add-port
    bridge: br-eth1
  - name: br-eth2
    action: add-br
  - name: eth2
    action: add-port
    bridge: br-eth2
  - name: br-eth3
    action: add-br
  - name: eth3
    action: add-port
    bridge: br-eth3
  - name: br-eth4
    action: add-br
  - name: eth4
    action: add-port
    bridge: br-eth4
  - name: br-ex
    action: add-br
  - name: br-mgmt
    action: add-br
  - name: br-storage
    action: add-br
  - name: br-fw-admin
    action: add-br
  - bridges:
    - br-eth4
    - br-storage
    trunks:
    - 0
    action: add-patch
  - bridges:
    - br-eth1
    - br-ex
    trunks:
    - 0
    action: add-patch
  - bridges:
    - br-eth2
    - br-mgmt
    trunks:
    - 0
    action: add-patch
  - bridges:
    - br-eth0
    - br-fw-admin
    trunks:
    - 0
    action: add-patch
  - name: br-prv
    action: add-br
  - bridges:
    - br-eth3
    - br-prv
    action: add-patch
  interfaces:
    eth0:
      L2:
        vlan_splinters: "off"
    eth1:
      L2:
        vlan_splinters: "off"
    eth2:
      L2:
        vlan_splinters: "off"
    eth3:
      L2:
        vlan_splinters: "off"
    eth4:
      L2:
        vlan_splinters: "off"
  endpoints:
    br-fw-admin:
      IP:
      - 10.108.13.3/24
    br-mgmt:
      IP:
      - 10.108.20.3/24
    br-storage:
      IP:
      - 10.108.32.2/24
    br-prv:
      IP: none
    br-ex:
      gateway: 10.108.14.1
      IP:
      - 10.108.14.3/24
  roles:
    private: br-prv
    storage: br-storage
    ex: br-ex
    fw-admin: br-fw-admin
    management: br-mgmt
nodes:
- public_netmask: 255.255.255.0
  role: primary-controller
  public_address: 10.108.14.3
  uid: "1"
  storage_netmask: 255.255.255.0
  internal_netmask: 255.255.255.0
  internal_address: 10.108.20.3
  name: node-1
  fqdn: node-1.test.domain.local
  storage_address: 10.108.32.2
  swift_zone: "1"
- public_netmask: 255.255.255.0
  role: controller
  public_address: 10.108.14.4
  uid: "2"
  storage_netmask: 255.255.255.0
  internal_netmask: 255.255.255.0
  internal_address: 10.108.20.4
  name: node-2
  fqdn: node-2.test.domain.local
  storage_address: 10.108.32.3
  swift_zone: "2"
- public_netmask: 255.255.255.0
  role: controller
  public_address: 10.108.14.5
  uid: "3"
  storage_netmask: 255.255.255.0
  internal_netmask: 255.255.255.0
  internal_address: 10.108.20.5
  name: node-3
  fqdn: node-3.test.domain.local
  storage_address: 10.108.32.4
  swift_zone: "3"
rabbit:
  password: vsqhv8Hi
nova:
  user_password: QKwbJbgg
  db_password: zOgT4MTs
quantum_settings:
  database:
    passwd: ZS6ZJmwe
  keystone:
    admin_password: "6onP1sXa"
  predefined_routers:
    router04:
      external_network: net04_ext
      virtual: false
      internal_networks:
        - net04
      tenant: admin
  predefined_networks:
    net04:
      shared: false
      L2:
        network_type: vlan
        segment_id:
        physnet: physnet2
        router_ext: false
      L3:
        nameservers:
          - "8.8.4.4"
          - "8.8.8.8"
        floating:
        subnet: "192.168.111.0/24"
        enable_dhcp: true
        gateway: "192.168.111.1"
      tenant: admin
    net04_ext:
      shared: false
      L2:
        network_type: flat
        segment_id:
        physnet: physnet1
        router_ext: true
      L3:
        nameservers: []
        floating: "10.108.14.128:10.108.14.254"
        subnet: "10.108.14.0/24"
        enable_dhcp: false
        gateway: "10.108.14.1"
      tenant: admin
  L2:
    provider: ml2
    segmentation_type: vlan
    base_mac: fa:16:3e:00:00:00
    phys_nets:
      physnet1:
        vlan_range:
        bridge: br-ex
      physnet2:
        vlan_range: 1000:1030
        bridge: br-prv
  L3:
    use_namespaces: true
  metadata:
    metadata_proxy_shared_secret: QKemSD93
EOM
  end

  def get_def_config()
      return Marshal.load(Marshal.dump(@def_config))
  end
end

describe 'neutron::examples::ml2_agent' do

  let(:module_path) { '../' }
  #let(:title) { 'bond0' }
  let(:params) { {
      :fuel_settings => NeutronConfig.new().get_def_config()
  } }
  let(:facts) { {
    :l3_fqdn_hostname => 'node-1',
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }

  it '(vlan) configures ml2_conf.ini' do
    should contain_neutron_plugin_ml2('agent/polling_interval').with_value("2")
    should contain_neutron_plugin_ml2('agent/l2_population').with_value("false")
    should contain_neutron_plugin_ml2('agent/arp_responder').with_value("false")
    should contain_neutron_plugin_ml2('ovs/bridge_mappings').with_value("physnet1:br-ex,physnet2:br-prv")
    should contain_neutron_plugin_ml2('ovs/integration_bridge').with_value("br-int")
    should contain_neutron_plugin_ml2('ovs/enable_tunneling').with_value("false")
    should contain_neutron_plugin_ml2('ovs/tunnel_bridge').with_ensure('absent')
    should contain_neutron_plugin_ml2('ovs/local_ip').with_ensure('absent')
  end

  # it '(vlan) should create plugin symbolic link' do
  #   should contain_file('/etc/neutron/plugin.ini').with(
  #     :ensure  => 'link',
  #     :target  => '/etc/neutron/plugins/ml2/ml2_conf.ini'
  #   )
  # end

end

describe 'neutron::examples::ml2_agent' do

  f_settings = NeutronConfig.new().get_def_config()
  f_settings['quantum_settings']['L2']['segmentation_type'] = 'gre'
  f_settings['quantum_settings']['predefined_networks']['net04']['L2']['network_type'] = 'gre'
  f_settings['quantum_settings']['predefined_networks']['net04']['L2'].delete('physnet')

  let(:module_path) { '../' }
  let(:params) { {
    :fuel_settings => f_settings
  } }
  let(:facts) { {
    :l3_fqdn_hostname => 'node-1',
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }

  it '(gre) configures ml2_conf.ini' do
    should contain_neutron_plugin_ml2('agent/polling_interval').with_value("2")
    should contain_neutron_plugin_ml2('agent/l2_population').with_value("false")
    should contain_neutron_plugin_ml2('agent/arp_responder').with_value("false")
    should contain_neutron_plugin_ml2('agent/tunnel_types').with_value("gre")
    should contain_neutron_plugin_ml2('ovs/bridge_mappings')
    should contain_neutron_plugin_ml2('ovs/enable_tunneling').with_value("true")
    should contain_neutron_plugin_ml2('ovs/integration_bridge').with_value("br-int")
  end

  # it '(gre) should create plugin symbolic link' do
  #   should contain_file('/etc/neutron/plugin.ini').with(
  #     :ensure  => 'link',
  #     :target  => '/etc/neutron/plugins/ml2/ml2_conf.ini'
  #   )
  # end

end

describe 'neutron::examples::ml2_agent' do

  f_settings = NeutronConfig.new().get_def_config()
  f_settings['quantum_settings']['L2']['segmentation_type'] = 'vxlan'

  let(:module_path) { '../' }
  let(:params) { {
    :fuel_settings => f_settings
  } }
  let(:facts) { {
    :l3_fqdn_hostname => 'node-1',
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }

  it '(vxlan) configures ml2_conf.ini' do
    should contain_neutron_plugin_ml2('agent/polling_interval').with_value("2")
    should contain_neutron_plugin_ml2('agent/l2_population').with_value("false")
    should contain_neutron_plugin_ml2('agent/arp_responder').with_value("false")
    should contain_neutron_plugin_ml2('agent/tunnel_types').with_value("vxlan")
    should contain_neutron_plugin_ml2('ovs/bridge_mappings')
    should contain_neutron_plugin_ml2('ovs/integration_bridge').with_value("br-int")
    should contain_neutron_plugin_ml2('ovs/enable_tunneling').with_value("true")
  end

  # it '(gre) should create plugin symbolic link' do
  #   should contain_file('/etc/neutron/plugin.ini').with(
  #     :ensure  => 'link',
  #     :target  => '/etc/neutron/plugins/ml2/ml2_conf.ini'
  #   )
  # end

end

describe 'neutron::examples::ml2_agent' do

  f_settings = NeutronConfig.new().get_def_config()
  f_settings['quantum_settings']['L2']['segmentation_type'] = 'vxlan'
  f_settings['quantum_settings']['L2']['tunnel_types'] = 'vxlan,gre'

  let(:module_path) { '../' }
  let(:params) { {
    :fuel_settings => f_settings
  } }
  let(:facts) { {
    :l3_fqdn_hostname => 'node-1',
    :osfamily => 'Debian',
    :operatingsystem => 'Ubuntu',
    :kernel => 'Linux'
  } }

  it '(vxlan) pass tunnel_types parameter' do
    should contain_neutron_plugin_ml2('ovs/enable_tunneling').with_value("true")
    should contain_neutron_plugin_ml2('agent/tunnel_types').with_value("vxlan,gre")
  end


end

###