# == Class: l23network
#
# Module for configuring network. Contains L2 and L3 modules.
# Requirements, packages and services.
#
class l23network (
  $use_ovs       = true,
  $use_lnx       = true,
  $install_ovs   = true,
  $install_brctl = true,
){

  include ::l23network::params

  class { 'l23network::l2':
    use_ovs       => $use_ovs,
    use_lnx       => $use_lnx,
    install_ovs   =>  $install_ovs,
    install_brctl =>  $install_brctl,
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
      ensure  => directory,
      owner   => 'root',
      mode    => '0755',
      recurse => true,    # for downstream files !!!
    }
  }
  Class['l23network::l2'] -> File<| title == "${::l23network::params::interfaces_dir}" |>
  Class['l23network::l2'] -> File<| title == "${::l23network::params::interfaces_file}" |>

  # Centos interface up-n-down scripts
  if $::osfamily =~ /(?i)redhat/: {
    class{'l23network::l2::centos_upndown_scripts': stage=>$stage }
    Anchor <| title == 'l23network::l2::centos_upndown_scripts' |> -> File<| title == "${::l23network::params::interfaces_dir}" |>
  }

  Anchor['l23network::l2::init'] -> Anchor['l23network::init']
  anchor { 'l23network::init': }

}
#
###
