class l23network::examples::bond_lnx (
    $bond            = $name,
    $interfaces      = ['eth4','eth5'],
    $ipaddr          = '10.20.30.40/27',
    #$bond_master     = undef,
    $bond_properties = {
        mode       => 1,
        miimon     => 100,
        lacp_rate  => 1,
    },
) {
    l23network::l3::ifconfig {$bond:
        ipaddr          => $ipaddr,
        bond_properties => $bond_properties,
    } ->
    l23network::l3::ifconfig {$interfaces[0]: ipaddr=>'none', bond_master=>$bond} ->
    l23network::l3::ifconfig {$interfaces[1]: ipaddr=>'none', bond_master=>$bond}
}
###