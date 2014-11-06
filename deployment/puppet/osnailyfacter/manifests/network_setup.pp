define setup_main_interfaces (
  $interface = $name,
  $network_settings
) {
  # Detect main interfaces, except bondXXX/brXXX/vlanXXX, XXX - pos int numbers with 0
  if $interface =~ /^(?!bond|br|vlan)\w+\d+$/ {
    if ! defined(L23network::L3::Ifconfig[$interface]) {
      $ipaddr = $network_settings[$interface]['ipaddr']
      $gateway = $network_settings[$interface]['gateway']
      # TODO implement bond slaves options support
      #$bond_master = $network_settings[$interface]['bond_master']
      notify{"${interface} => ${ipaddr}, ${gateway}":} ->
      l23network::l3::ifconfig{$interface:
        ipaddr        => $ipaddr,
        gateway       => $gateway,
        #bond_master   => $bond_master,
        check_by_ping => 'none'
      }
    }
  }
}

define setup_bond_interfaces (
  $interface = $name,
  $network_settings
) {
  # Detect main bond interfaces, allow bondXXX (alphanum only, XXX - pos int numbers with 0)
  if $interface =~ /^bond\d+$/ {
    if ! defined(L23network::L3::Ifconfig[$interface]) {
      # TODO implement bond options support
      #$bond_mode = $network_settings[$interface]['bond_mode']
      #$bond_miimon = $network_settings[$interface]['bond_miimon']
      #$bond_lacp_rate = $network_settings[$interface]['bond_lacp_rate']
      notify{"Stub for bond interface ${interface}":} #->
      #l23network::l3::ifconfig{$interface:
        #ipaddr          => $ipaddr,
        #gateway         => $gateway,
        #bond_mode       => $bond_mode,
        #bond_miimon     => $bond_miimon,
        #bond_lacp_rate  => $bond_lacp_rate,
        #check_by_ping   => 'none'
      #}
    }
  }
}

define setup_sub_interfaces (
  $interface = $name,
  $network_settings
) {
  # Detect sub interfaces, allow vlanXXX, anythingXXX.YYY (alphanum only, XXX&YYY - pos int numbers with 0)
  if $interface =~ /(^(\w+\d+)(\.)(\d+)$)|(^vlan\d+$)/ {
    if ! defined(L23network::L3::Ifconfig[$interface]) {
      $ipaddr = $network_settings[$interface]['ipaddr']
      $gateway = $network_settings[$interface]['gateway']
      # TODO implement bond slaves options support
      #$bond_master = $network_settings[$interface]['bond_master']
      notify{"${interface} => ${ipaddr}, ${gateway}":} ->
      l23network::l3::ifconfig{$interface:
        ipaddr        => $ipaddr,
        gateway       => $gateway,
        #bond_master   => $bond_master,
        check_by_ping => 'none'
      }
    }
  }
}

class osnailyfacter::network_setup (
  $interfaces = keys($::fuel_settings['network_data']),
  $network_settings = $::fuel_settings['network_data'],
) {
  setup_bond_interfaces{$interfaces: network_settings=>$network_settings} ->
  setup_main_interfaces{$interfaces: network_settings=>$network_settings} ->
  setup_sub_interfaces{$interfaces: network_settings=>$network_settings}
}
