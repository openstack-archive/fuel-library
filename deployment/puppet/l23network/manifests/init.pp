# == Class: l23network
#
# Module for configuring network. Contains L2 and L3 modules.
# Requirements, packages and services.
#
class l23network (
  $use_ovs          = true,
  $use_lnx          = true,
  $install_ovs      = $use_ovs,
  $install_brtool   = $use_lnx,
  $install_ethtool  = $use_lnx,
  $install_bondtool = $use_lnx,
  $install_vlantool = $use_lnx,
){

  include stdlib
  include ::l23network::params

  class { 'l23network::l2':
    use_ovs          => $use_ovs,
    use_lnx          => $use_lnx,
    install_ovs      => $install_ovs,
    install_brtool   => $install_brtool,
    install_ethtool  => $install_ethtool,
    install_bondtool => $install_bondtool,
    install_vlantool => $install_vlantool,
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
  Class['l23network::l2'] -> File<| title == "${::l23network::params::interfaces_dir}" |>
  Class['l23network::l2'] -> File<| title == "${::l23network::params::interfaces_file}" |>

  # Centos interface up-n-down scripts
  if $::osfamily =~ /(?i)redhat/ {
    class{'::l23network::l2::centos_upndown_scripts': } -> Anchor['l23network::init']
    Anchor <| title == 'l23network::l2::centos_upndown_scripts' |> -> Anchor['l23network::init']
  }


  Anchor['l23network::l2::init'] -> Anchor['l23network::init']
  anchor { 'l23network::init': }

}
#
###
