class l23network::examples::adv_net_config__bond_ovs (
    $fuel_settings,
) {
    class {'l23network': use_ovs=>true}

    prepare_network_config($fuel_settings['network_scheme'])
    $sdn = generate_network_config()
}
###