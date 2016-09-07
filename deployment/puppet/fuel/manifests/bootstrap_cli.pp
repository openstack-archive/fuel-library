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

  $default_settings = {
    root_ssh_authorized_file => "/root/.ssh/id_rsa.pub",
    extend_kopts =>  "biosdevname=0 net.ifnames=1 debug ignore_loglevel log_buf_len=10M print_fatal_signals=1 LOGLEVEL=8",
    output_dir => "/tmp/",
    ubuntu_release => "xenial",
    kernel_flavor => "linux-image-generic-lts-xenial",
    extra_dirs => ["/usr/share/fuel_bootstrap_cli/files/xenial"],
    packages => [
      "daemonize",
      "fuel-agent",
      "hwloc",
      "i40e-dkms",
      "linux-firmware",
      "linux-headers-generic",
      "live-boot",
      "live-boot-initramfs-tools",
      "mc",
      "mcollective",
      "msmtp-mta",
      "multipath-tools",
      "multipath-tools-boot",
      "nailgun-agent",
      "nailgun-mcagents",
      "network-checker",
      "ntp",
      "ntpdate",
      "openssh-client",
      "openssh-server",
      "puppet",
      "squashfs-tools",
      "ubuntu-minimal",
      "vim",
      "wget",
      "xz-utils"
    ],
    bootstrap_images_dir => "/var/www/nailgun/bootstraps",
    active_bootstrap_symlink => "/var/www/nailgun/bootstraps/active_bootstrap"
  }
  $additional_settings = {'direct_repo_addresses' => $direct_repo_addresses}
  $custom_settings = merge($default_settings, $settings, $additional_settings)

  ensure_packages([$bootstrap_cli_package])

  file { $config_path :
    content => template('fuel/fuel_bootstrap_cli.yaml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
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
