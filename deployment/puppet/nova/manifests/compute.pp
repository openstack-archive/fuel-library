# == Class: nova::compute
#
# Installs the nova-compute service
#
# === Parameters:
#
# [*enabled*]
#   (optional) Whether to enable the nova-compute service
#   Defaults to false
#
# [*heal_instance_info_cache_interval*]
#   (optional) Controls how often the instance info should be updated.
#    Defaults to '60' , to disable you can set the value to zero.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The state for the nova-compute package
#   Defaults to 'present'
#
# [*vnc_enabled*]
#   (optional) Whether to use a VNC proxy
#   Defaults to true
#
# [*vncserver_proxyclient_address*]
#   (optional) The IP address of the server running the VNC proxy client
#   Defaults to '127.0.0.1'
#
# [*vncproxy_host*]
#   (optional) The host of the VNC proxy server
#   Defaults to false
#
# [*vncproxy_protocol*]
#   (optional) The protocol to communicate with the VNC proxy server
#   Defaults to 'http'
#
# [*vncproxy_port*]
#   (optional) The port to communicate with the VNC proxy server
#   Defaults to '6080'
#
# [*vncproxy_path*]
#   (optional) The path at the end of the uri for communication with the VNC proxy server
#   Defaults to '/vnc_auto.html'
#
# [*vnc_keymap*]
#   (optional) The keymap to use with VNC (ls -alh /usr/share/qemu/keymaps to list available keymaps)
#   Defaults to 'en-us'
#
# [*force_config_drive*]
#   (optional) Whether to force the config drive to be attached to all VMs
#   Defaults to false
#
# [*virtio_nic*]
#   (optional) Whether to use virtio for the nic driver of VMs
#   Defaults to false
#
# [*neutron_enabled*]
#   (optional) Whether to use Neutron for networking of VMs
#   Defaults to true
#
# [*network_device_mtu*]
#   (optional) The MTU size for the interfaces managed by nova
#   Defaults to undef
#
# [*instance_usage_audit*]
#   (optional) Generate periodic compute.instance.exists notifications.
#   Defaults to false
#
# [*instance_usage_audit_period*]
#   (optional) Time period to generate instance usages for.
#   Time period must be hour, day, month or year
#   Defaults to 'month'
#
#  [*force_raw_images*]
#   (optional) Force backing images to raw format.
#   Defaults to true
#
#  [*reserved_host_memory*]
#   Reserved host memory
#   The amount of memory in MB reserved for the host.
#   Defaults to '512'
#
#  [*compute_manager*]
#   Compute manager
#   The driver that will manage the running instances.
#   Defaults to nova.compute.manager.ComputeManager
#
#  [*default_availability_zone*]
#   (optional) Default compute node availability zone.
#   Defaults to nova
#
#  [*default_schedule_zone*]
#   (optional) Availability zone to use when user doesn't specify one.
#   Defaults to undef
#
#  [*internal_service_availability_zone*]
#   (optional) The availability zone to show internal services under.
#   Defaults to internal
#
#  [*pci_passthrough*]
#   (optional) Pci passthrough hash in format of:
#   Defaults to undef
#   Example
#  "[ { 'vendor_id':'1234','product_id':'5678' },
#     { 'vendor_id':'4321','product_id':'8765','physical_network':'default' } ] "
#
class nova::compute (
  $enabled                            = false,
  $manage_service                     = true,
  $ensure_package                     = 'present',
  $vnc_enabled                        = true,
  $vncserver_proxyclient_address      = '127.0.0.1',
  $vncproxy_host                      = false,
  $vncproxy_protocol                  = 'http',
  $vncproxy_port                      = '6080',
  $vncproxy_path                      = '/vnc_auto.html',
  $vnc_keymap                         = 'en-us',
  $force_config_drive                 = false,
  $virtio_nic                         = false,
  $neutron_enabled                    = true,
  $network_device_mtu                 = undef,
  $instance_usage_audit               = false,
  $instance_usage_audit_period        = 'month',
  $force_raw_images                   = true,
  $reserved_host_memory               = '512',
  $compute_manager                    = 'nova.compute.manager.ComputeManager',
  $default_availability_zone          = 'nova',
  $default_schedule_zone              = undef,
  $internal_service_availability_zone = 'internal',
  $heal_instance_info_cache_interval  = '60',
  $pci_passthrough                    = undef,
) {

  include ::nova::params

  nova_config {
    'DEFAULT/reserved_host_memory_mb':           value => $reserved_host_memory;
    'DEFAULT/compute_manager':                   value => $compute_manager;
    'DEFAULT/heal_instance_info_cache_interval': value => $heal_instance_info_cache_interval;
  }

  if ($vnc_enabled) {
    include ::nova::vncproxy::common
  }

  nova_config {
    'DEFAULT/vnc_enabled':                   value => $vnc_enabled;
    'DEFAULT/vncserver_proxyclient_address': value => $vncserver_proxyclient_address;
    'DEFAULT/vnc_keymap':                    value => $vnc_keymap;
  }

  if $neutron_enabled != true {
    # Install bridge-utils if we use nova-network
    package { 'bridge-utils':
      ensure => present,
      before => Nova::Generic_service['compute'],
    }
  }

  nova::generic_service { 'compute':
    enabled        => $enabled,
    manage_service => $manage_service,
    package_name   => $::nova::params::compute_package_name,
    service_name   => $::nova::params::compute_service_name,
    ensure_package => $ensure_package,
    before         => Exec['networking-refresh']
  }

  if $force_config_drive {
    nova_config { 'DEFAULT/force_config_drive': value => true }
  } else {
    nova_config { 'DEFAULT/force_config_drive': ensure => absent }
  }

  if $virtio_nic {
    # Enable the virtio network card for instances
    nova_config { 'DEFAULT/libvirt_use_virtio_for_bridges': value => true }
  }

  if $network_device_mtu {
    nova_config {
      'DEFAULT/network_device_mtu':   value => $network_device_mtu;
    }
  } else {
    nova_config {
      'DEFAULT/network_device_mtu':   ensure => absent;
    }
  }

  if $instance_usage_audit and $instance_usage_audit_period in ['hour', 'day', 'month', 'year'] {
    nova_config {
      'DEFAULT/instance_usage_audit':        value => $instance_usage_audit;
      'DEFAULT/instance_usage_audit_period': value => $instance_usage_audit_period;
    }
  } else {
    nova_config {
      'DEFAULT/instance_usage_audit':        ensure => absent;
      'DEFAULT/instance_usage_audit_period': ensure => absent;
    }
  }

  package { 'pm-utils':
    ensure => present,
  }

  nova_config {
    'DEFAULT/force_raw_images': value => $force_raw_images;
  }

  nova_config {
    'DEFAULT/default_availability_zone':          value => $default_availability_zone;
    'DEFAULT/internal_service_availability_zone': value => $internal_service_availability_zone;
  }

  if $default_schedule_zone {
    nova_config {
      'DEFAULT/default_schedule_zone': value => $default_schedule_zone;
    }
  }

  if ($pci_passthrough) {
    nova_config {
      'DEFAULT/pci_passthrough_whitelist': value => check_array_of_hash($pci_passthrough);
    }
  }
}
