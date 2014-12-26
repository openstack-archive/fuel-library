# This manifest will only prepare config files and convert
# script in /root/ifcfg directory, but it will not run it.

$fuel_settings = parseyaml($astute_settings_yaml)

class { 'osnailyfacter::custom_network':
  network_scheme => $::fuel_settings['network_scheme'],
  role           => $::fuel_settings['role'],
  run_exec       => false,
}

