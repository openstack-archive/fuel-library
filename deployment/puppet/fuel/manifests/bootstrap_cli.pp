#
# == Class: fuel::bootstrap_cli
#
# Installs and configures fuel-bootstrap-cli package
#
# === Parameters
#
# [*bootstrap_cli_package*]
#  (optional) The bootstrap cli package name
#  Defaults to 'fuel-bootstrap-cli'
#
# [*settings*]
#  (optional) The hash of new settings for bootstrap cli package.
#  It will be merged with current package's settings(config_path)
#  and parameters from current variable will have highest priority
#  in case of equal parameters in both configuration sources.
#  Defaults to {}
#
# [*direct_repo_addresses*]
#  (optional) Array containing direct repositories ip addresses.
#  Proxy servers will not be used for these ip addresses.
#  Defaults to ['127.0.0.1']
#
# [*config_path*]
#  (optional) The path to configuration file of bootstrap cli package
#  Defaults to '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml'
#
# [*config_wgetrc*]
#  (optional) Boolean. Writes more robust wgetrc config for the system
#  Defaults to 'false'
#
# === Examples
#
# class { 'fuel::bootstrap_cli':
#   bootstrap_cli_package => 'fuel-bootstrap-cli',
#   settings              => {},
#   direct_repo_addresses => [ '192.168.0.1' ],
#   config_path           => '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml',
#   config_wgetrc         => true,
# }
#
class fuel::bootstrap_cli(
  $bootstrap_cli_package  = 'fuel-bootstrap-cli',
  $settings               = {},
  $direct_repo_addresses  = ['127.0.0.1'],
  $config_path            = '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml',
  $config_wgetrc          = false,
  ) {

  $additional_settings = {'direct_repo_addresses' => $direct_repo_addresses}
  $custom_settings = merge($settings, $additional_settings)

  ensure_packages([$bootstrap_cli_package])

  merge_yaml_settings { $config_path :
    ensure        => 'present',
    path          => $config_path,
    original_data => $config_path,
    override_data => $custom_settings,
    require       => Package[$bootstrap_cli_package],
  }

  if $config_wgetrc {
    augeas { 'Add robust wgetrc settings':
      lens    => 'Simplevars.lns',
      incl    => '/etc/wgetrc',
      changes => [
        'set timeout 60',
        'set waitretry 2',
        'set tries 5',
        'set dot_style mega',
        'set retry_connrefused on',
      ]
    }
  }
}
