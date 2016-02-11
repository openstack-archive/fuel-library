# xxx
class l23network::examples::run_network_scheme (
  $settings_yaml
){

    # this need for run spec tests only
    Package<||> { provider => apt }

    class {'::l23network': }

    $config = parseyaml($settings_yaml)
    prepare_network_config($config['network_scheme'])
    $sdn = generate_network_config()
    notice("SDN ${sdn}")
}
