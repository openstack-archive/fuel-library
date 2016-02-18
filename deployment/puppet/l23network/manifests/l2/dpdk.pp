class l23network::l2::dpdk (
  $ensure_package               = 'present',
  $use_dpdk                     = false,
  $install_ovs                  = $use_ovs,
  $install_dpdk                 = $use_dpdk,
  $ovs_dpdk_package_name        = $::l23network::params::ovs_dpdk_package_name,
  $ovs_dpdk_dkms_package_name   = $::l23network::params::ovs_dpdk_dkms_package_name,
  $dpdk_dir                     = $::l23network::params::dpdk_dir,
  $dpdk_conf_file               = $::l23network::params::dpdk_conf_file,
  $dpdk_interfaces_file         = $::l23network::params::dpdk_interfaces_file,
  $ovs_default_file             = $::l23network::params::ovs_default_file,
  $ovs_core_mask                = $::l23network::params::ovs_core_mask,
  $ovs_pmd_core_mask            = undef,
  $ovs_socket_mem               = $::l23network::params::ovs_socket_mem,
  $ovs_memory_channels          = $::l23network::params::ovs_memory_channels,
){
  include ::stdlib
  include ::l23network::params

  if $use_dpdk {
    service {'dpdk':
      ensure    => 'running',
      name      => 'dpdk',
      enable    => true,
      hasstatus => true,
    }

    if $dpdk_dir and $dpdk_conf_file and $dpdk_interfaces_file {
      $dpdk_interfaces = get_dpdk_interfaces()

      file {$dpdk_dir:
        ensure => directory,
      } ->
      file {$dpdk_conf_file:
        ensure => present,
        source => 'puppet:///modules/l23network/dpdk.conf',
      } ->
      file {$dpdk_interfaces_file:
        ensure => present,
        content => template('l23network/dpdk_interfaces.erb'),
      } ~> Service['dpdk']
    }

    if $ovs_default_file {
      file {$ovs_default_file:
        ensure => present,
        content => template('l23network/openvswitch_default_Debian.erb'),
      } ~> Service['openvswitch-service']
      Service['dpdk'] -> File[$ovs_default_file]
    }

    if $install_dpdk and $install_ovs {
      if $ovs_dpdk_dkms_package_name {
        package {'dpdk-dkms':
          ensure => $ensure_package,
          name   => $ovs_dpdk_dkms_package_name,
        }
        Package['dpdk-dkms'] -> Service['dpdk']
      }

      if $ovs_dpdk_package_name {
        package {'openvswitch-dpdk':
          ensure => $ensure_package,
          name   => $ovs_dpdk_package_name,
        } ~> Service['openvswitch-service']

        if $ovs_default_file {
          Package['openvswitch-dpdk'] -> File[$ovs_default_file]
        }
      }
    }
  }
}