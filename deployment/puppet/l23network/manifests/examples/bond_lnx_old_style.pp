class l23network::examples::bond_lnx_old_style (
    $bond            = $name,
    $interfaces      = ['eth4','eth5'],
    $ipaddr          = '10.20.30.40/27',
    #$bond_master     = undef,
    $bond_mode       = 1,
    $bond_miimon     = 100,
    $bond_lacp_rate  = 1,
) {
    l23network::l3::ifconfig {$bond:
        ipaddr          => $ipaddr,
        bond_mode       => $bond_mode,
        bond_miimon     => $bond_miimon,
        bond_lacp_rate  => $bond_lacp_rate,
    } ->
    l23network::l3::ifconfig {$interfaces[0]: ipaddr=>'none', bond_master=>$bond} ->
    l23network::l3::ifconfig {$interfaces[1]: ipaddr=>'none', bond_master=>$bond}
}
###