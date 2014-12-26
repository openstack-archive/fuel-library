# This class is used to provide custom network setup with linux bonds
# and linux vlans.
#
# ==Parameters
#
# [network_scheme] Neutron network scheme from astute.yaml
#
# [role] Node role
#
# [run_exec] boolean, should we apply changes or only prepare configs
# and script.

class custom_project::convert_to_linux_bonds (
  $network_scheme,
  $role,
  $mgmt_vlan,
  $storage_vlan,
  $ext_vlan,
  $run_exec = false,
){
  # Type that will create ifcfgs for us
  define ifcfg_file (
    $device = $name,
    $ipaddr = false,
    $netmask = false,
    $gateway = false,
    $mtu = false,
    $vlan = false,
    $ethtool_opts = false,
    $bond_master = false,
    $bonding_opts = false,
  ) {
    file {"/root/ifcfg/ifcfg-${device}":
      ensure  => file,
      mode    => '0644',
      content => inline_template('
DEVICE=<%= @device %>
BOOTPROTO=none
ONBOOT=yes
USERCTL=no
TYPE=Ethernet
<% if @ipaddr -%>
IPADDR=<%= @ipaddr %>
<% end -%>
<% if @netmask -%>
NETMASK=<%= @netmask %>
<% end -%>
<% if @mtu -%>
MTU=<%= @mtu %>
<% end -%>
<% if @bond_master -%>
MASTER=<%= @bond_master %>
SLAVE=yes
<% end -%>
<% if @vlan -%>
VLAN=yes
<% end -%>
<% if @gateway -%>
GATEWAY=<%= @gateway %>
<% end -%>
<% if @ethtool_opts -%>
ETHTOOL_OPTS="<%= @ethtool_opts %>"
<% end -%>
<% if @bonding_opts -%>
BONDING_OPTS="<%= @bonding_opts %>"
<% end -%>
')
    }
  }
  # Getting needed info from network transformations
  $bond0_properties = inline_template("<%= begin @network_scheme['transformations'].find{|n| n['action'] == 'add-bond' and n['bridge'] == 'br-ovs-bond0'}['properties'].join(' ') rescue 'fail' end %>")

  $cidr_br_ex = $network_scheme['endpoints']['br-ex']['IP'][0]
  $ext_address = inline_template("<%= begin @cidr_br_ex.split('/').first rescue 'fail' end %>")
  $ext_netmask = inline_template("<%= begin IPAddr.new('255.255.255.255').mask(@cidr_br_ex.split('/').last).to_s rescue 'fail' end %>")
  $ext_gateway = $network_scheme['endpoints']['br-ex']['gateway']

  $cidr_br_mgmt = $network_scheme['endpoints']['br-mgmt']['IP'][0]
  $mgmt_address = inline_template("<%= @cidr_br_mgmt.split('/').first %>")
  $mgmt_netmask = inline_template("<%= IPAddr.new('255.255.255.255').mask(@cidr_br_mgmt.split('/').last).to_s %>")

  $cidr_br_storage = $network_scheme['endpoints']['br-storage']['IP'][0]
  $storage_address = inline_template("<%= @cidr_br_storage.split('/').first %>")
  $storage_netmask = inline_template("<%= IPAddr.new('255.255.255.255').mask(@cidr_br_storage.split('/').last).to_s %>")

  $bond0_interfaces = split(inline_template("<%= @network_scheme['transformations'].find{|n| n['action'] == 'add-bond' and n['bridge'] == 'br-ovs-bond0'}['interfaces'].join(',') %>"), ',')
  # Role dependant settings
  case $role {
    /controller/ : {
      $bond1_interfaces = false
      ifcfg_file {"bond0.${storage_vlan}":
        ipaddr  => $storage_address,
        netmask => $storage_netmask,
        gateway => false,
        vlan    => true,
        mtu     => '9000',
        require => File['/root/ifcfg'],
      }
      $eth_ifs = join($bond0_interfaces, " ")
      $convert_script_name = 'convert_to_linux_bonds.sh'
    }
    "compute" : {
      $bond1_interfaces = split(inline_template("<%= @network_scheme['transformations'].find{|n| n['action'] == 'add-bond' and n['bridge'] == 'br-ovs-bond1'}['interfaces'].join(',') %>"), ',')
      $eth_ifs_arr = split(inline_template("<%= @network_scheme['transformations'].find{|n| n['action'] == 'add-bond' and n['bridge'] == 'br-ovs-bond0'}['interfaces'].join(',') %>"), ',')
      ifcfg_file {"bond1":
        bonding_opts => "mode=802.3ad lacp_rate=0 miimon=100 xmit_hash_policy=layer3+4",
        mtu          => '9000',
        require      => File['/root/ifcfg'],
      }
      ifcfg_file {"bond1.${storage_vlan}":
        ipaddr  => $storage_address,
        netmask => $storage_netmask,
        gateway => false,
        vlan    => true,
        mtu     => '9000',
        require => File['/root/ifcfg'],
      }
      $eth_ifs = join(concat($eth_ifs_arr, $bond1_interfaces), ' ')
      $convert_script_name = 'convert_compute_to_linux_bonds.sh'
    }
  }

  file {'/root/ifcfg':
    ensure => directory,
  }
  file {'/root/ifcfg/convert_to_linux_bonds.sh':
    ensure  => file,
    content => template("custom_project/${convert_script_name}.erb"),
    mode    => '0755',
    require => File['/root/ifcfg'],
  }
  ifcfg_file {"bond0":
    bonding_opts => "mode=802.3ad lacp_rate=0 miimon=100 xmit_hash_policy=layer3+4",
    mtu          => '9000',
    require      => File['/root/ifcfg'],
  }
  ifcfg_file {"bond0.${ext_vlan}":
    mtu     => '9000',
    vlan    => true,
    require => File['/root/ifcfg'],
  }
  ifcfg_file {"bond0.${mgmt_vlan}":
    ipaddr  => $mgmt_address,
    netmask => $mgmt_netmask,
    gateway => false,
    vlan    => true,
    mtu     => '9000',
    require => File['/root/ifcfg'],
  }

  if $bond0_interfaces {
    ifcfg_file { $bond0_interfaces:
      bond_master  => 'bond0',
      ethtool_opts => '-K ${DEVICE} tso on lro off gro off gso on',
      mtu          => '9000',
      require => File['/root/ifcfg'],
    }
  }

  if $bond1_interfaces {
    ifcfg_file { $bond1_interfaces:
      bond_master  => 'bond1',
      ethtool_opts => '-K ${DEVICE} tso on lro off gro off gso on',
      mtu          => '9000',
      require => File['/root/ifcfg'],
    }
  }

  if $run_exec {
    exec { 'convert_to_linux_bonds':
      command => '/root/ifcfg/convert_to_linux_bonds.sh &> /var/log/convert_to_linux_bonds.log',
    }
    # Ordering
    Ifcfg_file<| |> -> Exec<| title == 'convert_to_linux_bonds'|>
  }
}
