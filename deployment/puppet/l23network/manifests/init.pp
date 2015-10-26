# == Class: l23network
#
# Module for configuring network. Contains L2 and L3 modules.
# Requirements, packages and services.
#
# === Parameters
#
# [*ensure_package*]
#   (optional) The state of used packages
#   Defaults to 'present'
#
# [*use_ovs_dkms_datapath_module*]
#   (optional) The usage of DKMS datapath openVswitch or kernel build-in module
#   Defaults to true
#
# [*ovs_module_name*]
#   (optional) The custom datapath openVswitch module name
#   Defaults to undef, the value from params.pp is used
#
# [*ovs_datapath_package_name*]
#   (optional) The custom name of datapath openVswitch package
#   Defaults to undef, the value from params.pp is used
#
# [*disable_hotplug*]
#   (optional) Enables to disable hotplug system temporarily during network configuration
#   Defaults to true
#
class l23network (
  $ensure_package               = 'present',
  $use_lnx                      = true,
  $use_ovs                      = false,
  $install_ovs                  = $use_ovs,
  $install_brtool               = $use_lnx,
  $install_ethtool              = $use_lnx,
  $install_bondtool             = $use_lnx,
  $install_vlantool             = $use_lnx,
  $ovs_module_name              = undef,
  $use_ovs_dkms_datapath_module = true,
  $ovs_datapath_package_name    = undef,
  $ovs_common_package_name      = undef,
  $disable_hotplug              = true,
){

  include stdlib
  include ::l23network::params

  class { 'l23network::l2':
    ensure_package               => $ensure_package,
    use_ovs                      => $use_ovs,
    use_lnx                      => $use_lnx,
    install_ovs                  => $install_ovs,
    install_brtool               => $install_brtool,
    install_ethtool              => $install_ethtool,
    install_bondtool             => $install_bondtool,
    install_vlantool             => $install_vlantool,
    ovs_module_name              => $ovs_module_name,
    use_ovs_dkms_datapath_module => $use_ovs_dkms_datapath_module,
    ovs_datapath_package_name    => $ovs_datapath_package_name,
    ovs_common_package_name      => $ovs_common_package_name,
  }

  if $::l23network::params::interfaces_file {
    if ! defined(File["${::l23network::params::interfaces_file}"]) {
      file {"${::l23network::params::interfaces_file}":
        ensure  => present,
        content => template('l23network/interfaces.erb'),
      }
    }
    File<| title == "${::l23network::params::interfaces_file}" |> -> File<| title == "${::l23network::params::interfaces_dir}" |>
  }

  if ! defined(File["${::l23network::params::interfaces_dir}"]) {
    file {"${::l23network::params::interfaces_dir}":
      ensure => directory,
      owner  => 'root',
      mode   => '0755',
    } -> Anchor['l23network::init']
  }
  Anchor['l23network::l2::init'] -> File<| title == "${::l23network::params::interfaces_dir}" |>
  Anchor['l23network::l2::init'] -> File<| title == "${::l23network::params::interfaces_file}" |>

  # Centos interface up-n-down scripts
  if $::l23_os =~ /(?i:redhat|centos)/ {
    class{'::l23network::l2::centos_upndown_scripts': } -> Anchor['l23network::init']
    Anchor <| title == 'l23network::l2::centos_upndown_scripts' |> -> Anchor['l23network::init']
  }

  #install extra tools
  ensure_packages($::l23network::params::extra_tools)

  Anchor['l23network::l2::init'] -> Anchor['l23network::init']
  anchor { 'l23network::init': }

  if $disable_hotplug {
    disable_hotplug { 'global':
      ensure => 'present',
    }
    Disable_hotplug['global'] -> Anchor['l23network::init']

    enable_hotplug { 'global':
      ensure => 'present',
    }
    Disable_hotplug['global'] -> Enable_hotplug['global']
    L2_port<||>               -> Enable_hotplug['global']
    L2_bridge<||>             -> Enable_hotplug['global']
    L2_bond<||>               -> Enable_hotplug['global']
    L3_ifconfig<||>           -> Enable_hotplug['global']
    L23_stored_config<||>     -> Enable_hotplug['global']
    L3_route<||>              -> Enable_hotplug['global']
  }
}
