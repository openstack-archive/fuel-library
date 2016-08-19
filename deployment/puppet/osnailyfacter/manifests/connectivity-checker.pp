notice('MODULAR: connectivity-checker.pp')

$plugin_name      = 'connectivity_checker'
$plugin_settings  = hiera_hash("${plugin_name}", {})
$task_deploy      = hiera('task_deploy', false)

connectivity_checker { 'netconfig':
  network_scheme   => hiera_hash('network_scheme'),
  network_metadata => hiera_hash('network_metadata'),
  non_destructive  => pick($plugin_settings['non_destructive'], false),
  ping_tries       => pick($plugin_settings['ping_tries'], 5),
  ping_timeout     => pick($plugin_settings['ping_timeout'], 20),
}
