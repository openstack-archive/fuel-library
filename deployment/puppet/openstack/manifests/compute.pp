#
# == Class: openstack::compute
#
# Manifest to install/configure nova-compute
#
# === Parameters
#
# See params.pp
#
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [public_interface] Public interface used to route public traffic. Optional.
#   Defaults to false.
# [fixed_range] Range of ipv4 network for vms.
# [network_manager] Nova network manager to use.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [sql_connection] SQL connection information. Optional. Defaults to false
#   which indicates that exported resources will be used to determine connection
#   information.
# [nova_user_password] Nova service password.
#  [rabbit_nodes] RabbitMQ nodes or false. Optional. Defaults to false.
#  [rabbit_password] RabbitMQ password. Optional. Defaults to  'rabbit_pw',
#  [rabbit_user] RabbitMQ user. Optional. Defaults to 'nova',
#  [glance_api_servers] List of glance api servers of the form HOST:PORT
#    delimited by ':'. False indicates that the resource should be collected.
#    Optional. Defaults to false,
#  [libvirt_type] Underlying libvirt supported hypervisor.
#    Optional. Defaults to 'kvm',
#  [vncproxy_host] Host that serves as vnc proxy. Optional.
#    Defaults to false. False indicates that a vnc proxy should not be configured.
#  [vnc_enabled] Rather vnc console should be enabled.
#    Optional. Defaults to 'true',
#  [verbose] Rather components should log verbosely.
#    Optional. Defaults to false.
#  [manage_volumes] Rather nova-volume should be enabled on this compute node.
#    Optional. Defaults to false.
#  [nova_volumes] Name of volume group in which nova-volume will create logical volumes.
#    Optional. Defaults to nova-volumes.
#
# class { 'openstack::nova::compute':
#   internal_address   => '192.168.2.2',
#   vncproxy_host      => '192.168.1.1',
#   nova_user_password => 'changeme',
# }

class openstack::compute (
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password,
  # Network
  # DB
  $sql_connection                = false,
  # Nova
  $purge_nova_config              = false,
  # Rabbit
  $rabbit_nodes        = false,
  $rabbit_password     = 'rabbit_pw',
  $rabbit_host                   = false,
  $rabbit_user                   = 'nova',
  # Glance
  $glance_api_servers            = false,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  # General
  $enabled                       = true,
  $multi_host			 = false,
  $public_interface,
  $private_interface,
  $network_manager,
  $fixed_range,
  $quantum			= false,
  $cinder			= false,
  # nova compute configuration parameters
  $verbose             = false,
  $manage_volumes      = false,
    $cache_server_ip         = ['127.0.0.1'],
  $cache_server_port       = '11211',
  $nova_volume         = 'nova-volumes',
  $service_endpoint	= '127.0.0.1',
  $ssh_private_key = undef,
  $ssh_public_key = undef,
) {

  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ! defined( Resources[nova_config] ) {
    if ($purge_nova_config) {
      resources { 'nova_config':
        purge => true,
      }
    }
  }

  $final_sql_connection = $sql_connection
  $glance_connection = $glance_api_servers
  $rabbit_connection = $rabbit_host
  include ntpd

  augeas { "libvirt-conf":
    context => "/files/etc/libvirt/libvirtd.conf",
    changes =>[
      "set listen_tls 0",
      "set listen_tcp 1",
      "set auth_tcp none",
    ];
  }

  $memcached_addresses =  inline_template("<%= @cache_server_ip.collect {|ip| ip + ':' + @cache_server_port }.join ',' %>")
  nova_config {'DEFAULT/memcached_servers':
    value => $memcached_addresses
  }


  class { 'nova':
    ensure_package     => $::openstack_version['nova'],
    sql_connection     => $sql_connection,
    rabbit_nodes       => $rabbit_nodes,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_api_servers,
    verbose            => $verbose,
    rabbit_host        => $rabbit_host,
  }

  if ($cinder) {
    $enabled_apis			= 'ec2,osapi_compute,metadata'
    package {'python-cinderclient': ensure => present}
  } else {
    $enabled_apis = 'ec2,osapi_compute,metadata,osapi_volume'
  }


  # Install / configure nova-compute
  class { '::nova::compute':
     ensure_package                 => $::openstack_version['nova'],
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $vncproxy_host,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => $internal_address,
  }

  if ( $ssh_private_key != undef ) {
    file { '/var/lib/nova/.ssh':
      ensure => directory,
      owner => 'nova',
      group => 'nova',
      mode => '0700'
    }
    file { '/var/lib/nova/.ssh/authorized_keys':
      ensure => present,
      owner => 'nova',
      group => 'nova',
      mode => '0400',
      source => $ssh_public_key,
    }
    file { '/var/lib/nova/.ssh/id_rsa':
      ensure => present,
      owner => 'nova',
      group => 'nova',
      mode => '0400',
      source => $ssh_private_key,
    }
    file { '/var/lib/nova/.ssh/id_rsa.pub':
      ensure => present,
      owner => 'nova',
      group => 'nova',
      mode => '0400',
      source => $ssh_public_key,
    }
    file { '/var/lib/nova/.ssh/config':
      ensure => present,
      owner => 'nova',
      group => 'nova',
      mode => '0600',
      content => "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n",
    }
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if $multi_host {
    include keystone::python
    nova_config {
      'DEFAULT/multi_host':      value => 'True';
      'DEFAULT/send_arp_for_ha': value => 'True';
    }
    if ! $public_interface {
      fail('public_interface must be defined for multi host compute nodes')
    }
    $enable_network_service = true
    class { 'nova::api':
      ensure_package    => $::openstack_version['nova'],
      enabled           => true,
      admin_tenant_name => 'services',
      admin_user        => 'nova',
      admin_password    => $nova_user_password,
      enabled_apis	=> $enabled_apis,
      auth_host          => $service_endpoint
      # TODO override enabled_apis
    }

  } else {
    $enable_network_service = false
    nova_config {
      'DEFAULT/multi_host':      value => 'False';
      'DEFAULT/send_arp_for_ha': value => 'False';
    }
  }

  if $quantum == false {
    class { 'nova::network':
      ensure_package    => $::openstack_version['nova'],
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => $floating_range,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => $really_create_networks,
      num_networks      => $num_networks,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
    }
  }

}
