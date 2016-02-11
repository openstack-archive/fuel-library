# xxx
class l23network::examples::run_network_scheme (
  $settings_yaml
){

    include ::l23network::params

    # this is a workaround for run spec tests not only on Linux platform
    if $::l23network::params::network_manager_name != undef {
      Package<| title == $::l23network::params::network_manager_name |> { provider => apt }
    }

    class {'::l23network': }

    $config = parseyaml($settings_yaml)
    prepare_network_config($config['network_scheme'])
    $sdn = generate_network_config()
    notice("SDN ${sdn}")
}
