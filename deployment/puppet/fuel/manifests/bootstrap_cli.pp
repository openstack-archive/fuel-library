#
# == Class: nailgun::bootstrap_cli
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
# === Examples
#
# class { 'nailgun::bootstrap_cli':
#   bootstrap_cli_package => 'fuel-bootstrap-cli',
#   settings              => {},
#   direct_repo_addresses => [ '192.168.0.1' ],
#   config_path           => '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml',
# }
#
class fuel::bootstrap_cli(
  $bootstrap_cli_package  = 'fuel-bootstrap-cli',
  $settings               = {},
  $direct_repo_addresses  = ['127.0.0.1'],
  $config_path            = '/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml',
  ) {

  $additional_settings = {'direct_repo_addresses' => $direct_repo_addresses}
  $custom_settings = merge($settings, $additional_settings)

  package { $bootstrap_cli_package:
    ensure => present,
  }

  merge_yaml_settings { $config_path:
    sample_settings   => $config_path,
    override_settings => $custom_settings,
    ensure            => present,
    require           => Package[$bootstrap_cli_package],
  }
}
