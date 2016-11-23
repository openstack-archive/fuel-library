notice('MODULAR: connectivity-checker.pp')

$network_checker_settings = hiera_hash("connectivity_checker", {})
$exclude_network_roles = pick($network_checker_settings['exclude_network_roles'], [])

connectivity_checker { 'netconfig':
  network_scheme        => hiera_hash('network_scheme'),
  network_metadata      => hiera_hash('network_metadata'),
  non_destructive       => pick($network_checker_settings['non_destructive'], false),
  ping_tries            => pick($network_checker_settings['ping_tries'], 5),
  ping_timeout          => pick($network_checker_settings['ping_timeout'], 20),
  parallel_amount       => pick($network_checker_settings['parallel_amount'], 20),
  exclude_network_roles => $exclude_network_roles,
}
