# == Class: l23network::l2::dpdk
#
# Module for configuring DPDK-enabled OVS and interfaces.
#
# === Parameters
#
# [*use_dpdk*]
#   Initialize DPDK or not
#   Defaults to false
# [*install_dpdk*]
#   Install DPDK packages or not
#   Defaults to $use_dpdk
# [*ovs_core_mask*]
#   (optional) OpenVSwitch cpu core mask in hexa format
#   Defaults to 0x1
# [*ovs_pmd_core_mask*]
#   (optional) OpenVSwitch core mask in hexa format for PMD threads
#   Defaults to undef
# [*ovs_socket_mem*]
#   (optional) List of amounts of memory to allocate per NUMA node
#   Defaults to '128'
# [*ovs_memory_channels*]
#   (optional) Number of memory channels in CPU
#   Defaults to '2'
# [*ovs_vhost_owner*]
#   (optional) vhost_user sockets owner/group
#   Defaults to 'libvirt-qemu:kvm'
# [*ovs_vhost_perm*]
#   (optional) vhost_user sockets permissions
#   Defaults to '0664'
#
class l23network::l2::dpdk (
  $use_dpdk                    = $::l23network::use_dpdk,
  $install_dpdk                = $::l23network::install_dpdk,
  $ovs_core_mask               = $::l23network::params::ovs_core_mask,
  $ovs_pmd_core_mask           = undef,
  $ovs_socket_mem              = $::l23network::params::ovs_socket_mem,
  $ovs_memory_channels         = $::l23network::params::ovs_memory_channels,
  $ovs_vhost_owner             = $::l23network::params::ovs_vhost_owner,
  $ovs_vhost_perm              = $::l23network::params::ovs_vhost_perm,
  $ovs_dpdk_package_name       = $::l23network::params::ovs_dpdk_package_name,
  $ovs_dpdk_dkms_package_name  = $::l23network::params::ovs_dpdk_dkms_package_name,
  $dpdk_dir                    = $::l23network::params::dpdk_dir,
  $dpdk_conf_file              = $::l23network::params::dpdk_conf_file,
  $dpdk_interfaces_file        = $::l23network::params::dpdk_interfaces_file,
  $ovs_default_file            = $::l23network::params::ovs_default_file,
  $install_ovs                 = $::l23network::l2::install_ovs,
  $ensure_package              = 'present',
) inherits ::l23network::params {

  $_install_dpdk = pick($install_dpdk, $use_dpdk)

  if $use_dpdk {

    # Configure DPDK interfaces
    if $dpdk_dir and $dpdk_conf_file and $dpdk_interfaces_file {
      $dpdk_interfaces = get_dpdk_interfaces()

      file {$dpdk_dir:
        ensure => 'directory',
      } ->
      file {$dpdk_conf_file:
        ensure => 'present',
        source => 'puppet:///modules/l23network/dpdk.conf',
      } ->
      file {$dpdk_interfaces_file:
        ensure  => 'present',
        content => template('l23network/dpdk_interfaces.erb'),
      }
      File[$dpdk_interfaces_file] ~> Service['dpdk']
      File[$dpdk_interfaces_file] ~> Service['openvswitch-service']

      if $ovs_default_file {
        File[$dpdk_interfaces_file] -> File[$ovs_default_file]
      }
    } else {
      warning('DPDK was not configured')
    }

    # Install DPDK modules
    if $_install_dpdk and $ovs_dpdk_dkms_package_name {
      package {'dpdk-dkms':
        ensure => $ensure_package,
        name   => $ovs_dpdk_dkms_package_name,
      }
      Package['dpdk-dkms'] -> Service['dpdk']
    } else {
      warning('DPDK kernel module was not installed')
    }

    # Bind DPDK (it's safe to start it)
    service {'dpdk':
      ensure    => 'running',
      name      => 'dpdk',
      enable    => true,
      hasstatus => true,
    } -> Anchor['l23network::l2::dpdk']

    # Configure OpenVSwitch to use DPDK
    if $ovs_default_file {
      file {$ovs_default_file:
        ensure  => 'present',
        content => template('l23network/openvswitch_default_Debian.erb'),
      } ~> Service['openvswitch-service']
    }

    # Install DPDK-enabled OpenVSwitch
    if $_install_dpdk and $install_ovs and $ovs_dpdk_package_name {
      package {'openvswitch-dpdk':
        ensure => $ensure_package,
        name   => $ovs_dpdk_package_name,
      } ~> Service['openvswitch-service']

      if $ovs_default_file {
        Package['openvswitch-dpdk'] -> File[$ovs_default_file]
      }
    } else {
      warning('OpenVSwitch DPDK was not installed')
    }

    # Configure OVS DPDK PMD in runtime (it's safe to re-set it)
    if $ovs_pmd_core_mask {
      $ovs_pmd_core_mask_opts = { value => "$ovs_pmd_core_mask" }
    } else {
      $ovs_pmd_core_mask_opts = { ensure => 'absent' }
    }

    $dpdk_extra_opts = "-n ${ovs_memory_channels} --vhost-owner ${ovs_vhost_owner} --vhost-perm ${ovs_vhost_perm}"

    # Configure OpenVSwitch to use DPDK
    $vs_config = {
      'other_config:dpdk-init'       => { value => 'true' },
      'other_config:dpdk-socket-mem' => { value => join($ovs_socket_mem, ',') },
      'other_config:dpdk-lcore-mask' => { value => "$ovs_core_mask" },
      'other_config:dpdk-extra'      => { value => $dpdk_extra_opts },
      'other_config:pmd-cpu-mask'    => $ovs_pmd_core_mask_opts,
    }

    create_resources('vs_config', $vs_config)

    Service['dpdk'] -> Vs_config<||> ~> Service['openvswitch-service']

    # Install ifupdown scripts
    if $::l23_os =~ /(?i)ubuntu/ {
      file {'/etc/network/if-pre-up.d/ovsdpdk':
        ensure => 'present',
        owner  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/l23network/debian_ovsdpdk',
      } ->
      file {'/etc/network/if-post-down.d/ovsdpdk':
        ensure => 'present',
        owner  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/l23network/debian_ovsdpdk',
      } -> Anchor['l23network::l2::dpdk']
    }

    anchor { 'l23network::l2::dpdk': }
  }
}
