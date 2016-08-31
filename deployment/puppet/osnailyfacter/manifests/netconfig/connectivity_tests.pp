class osnailyfacter::netconfig::connectivity_tests {

  notice('MODULAR: netconfig/connectivity_tests.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  prepare_network_config($network_scheme)

  $run_ping_checker = hiera('run_ping_checker', true)

  if $run_ping_checker {
      # check that network was configured successfully
      # and the default gateway is online
      $default_gateway = get_default_gateways()

      ping_host { $default_gateway :
          ensure => 'up',
      }
      L2_port<||> -> Ping_host[$default_gateway]
      L2_bond<||> -> Ping_host[$default_gateway]
      L3_ifconfig<||> -> Ping_host[$default_gateway]
      L3_route<||> -> Ping_host[$default_gateway]
  }

  # Pull the list of repos from hiera
  $repo_setup = hiera('repo_setup')
  # test that the repos are accessible
  url_available($repo_setup['repos'])

}
