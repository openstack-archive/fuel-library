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
# [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [sql_connection] SQL connection information. Optional. Defaults to false
#   which indicates that exported resources will be used to determine connection
#   information.
# [nova_user_password] Nova service password.
#  [amqp_hosts] RabbitMQ hosts or false. Optional. Defaults to false.
#  [amqp_user] RabbitMQ user. Optional. Defaults to 'nova',
#  [amqp_password] RabbitMQ password. Optional. Defaults to  'rabbit_pw',
#  [glance_api_servers] List of glance api servers of the form HOST:PORT
#    delimited by ':'. False indicates that the resource should be collected.
#    Optional. Defaults to false,
#  [libvirt_type] Underlying libvirt supported hypervisor.
#    Optional. Defaults to 'kvm',
#  [vncproxy_host] Host that serves as vnc proxy. Optional.
#    Defaults to false. False indicates that a vnc proxy should not be configured.
#  [vnc_enabled] Rather vnc console should be enabled.
#    Optional. Defaults to 'true',
# [verbose] Rather to print more verbose (INFO+) output. If non verbose and non debug. Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option. Optional. Defaults to false.
#  [manage_volumes] Rather nova-volume should be enabled on this compute node.
#    Optional. Defaults to false.
#  [nova_volumes] Name of volume group in which nova-volume will create logical volumes.
#    Optional. Defaults to nova-volumes.
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [ssh_private_key] path to private ssh key temporary location on this server where it was uploaded or generated
# [ssh_public_key] path to public ssh key temporary location on this server where it was uploaded or generated
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
  $sql_connection                 = false,
  # Nova
  $purge_nova_config              = false,
  # RPC
  # FIXME(bogdando) replace queue_provider for rpc_backend once all modules synced with upstream
  $queue_provider                 = 'rabbitmq',
  $rpc_backend                    = 'nova.openstack.common.rpc.impl_kombu',
  $amqp_hosts                     = false,
  $amqp_user                      = 'nova',
  $amqp_password                  = 'rabbit_pw',
  $rabbit_ha_queues               = false,
  # Glance
  $glance_api_servers             = undef,
  # Virtualization
  $libvirt_type                   = 'kvm',
  # VNC
  $vnc_enabled                    = true,
  $vncproxy_host                  = undef,
  $vncserver_listen               = $internal_address,
  # General
  $enabled                        = true,
  $multi_host                     = false,
  $auto_assign_floating_ip        = false,
  $network_config                 = {},
  $public_interface,
  $private_interface,
  $network_manager,
  $fixed_range                    = undef,
  # Neutron
  $network_provider               = 'nova',
  $neutron_integration_bridge     = 'br-int',
  $neutron_user_password          = 'asdf1234',
  $base_mac                       = 'fa:16:3e:00:00:00',
  # Ceilometer
  $ceilometer_user_password       = 'ceilometer_pass',
  # nova compute configuration parameters
  $verbose                        = false,
  $debug                          = false,
  $service_endpoint               = '127.0.0.1',
  $ssh_private_key                = '/var/lib/astute/nova/nova',
  $ssh_public_key                 = '/var/lib/astute/nova/nova.pub',
  $cache_server_ip                = ['127.0.0.1'],
  $cache_server_port              = '11211',
  # if the cinder management components should be installed
  $manage_volumes                 = false,
  $nv_physical_volume             = undef,
  $cinder_volume_group            = 'cinder-volumes',
  $cinder                         = true,
  $cinder_user_password           = 'cinder_user_pass',
  $cinder_db_password             = 'cinder_db_pass',
  $cinder_db_user                 = 'cinder',
  $cinder_db_dbname               = 'cinder',
  $cinder_iscsi_bind_addr         = false,
  $db_host                        = '127.0.0.1',
  $use_syslog                     = false,
  $syslog_log_facility            = 'LOG_LOCAL6',
  $syslog_log_facility_neutron    = 'LOG_LOCAL4',
  $syslog_log_facility_ceilometer = 'LOG_LOCAL0',
  $nova_rate_limits               = undef,
  $nova_report_interval           = '10',
  $nova_service_down_time         = '60',
  $cinder_rate_limits             = undef,
  $create_networks                = false,
  $state_path                     = '/var/lib/nova',
  $ceilometer                     = false,
  $ceilometer_metering_secret     = 'ceilometer',
  $libvirt_vif_driver             = 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
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

  case $::osfamily {
    'RedHat': {
      augeas { 'sysconfig-libvirt':
        context => '/files/etc/sysconfig/libvirtd',
        lens => "shellvars.lns",
        incl => "/etc/sysconfig/libvirtd",
        changes => 'set LIBVIRTD_ARGS "--listen"',
        before  => Augeas['libvirt-conf'],
      }

      # From legacy libvirt.pp
      exec { 'symlink-qemu-kvm':
        command => '/bin/ln -sf /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64',
        creates => '/usr/bin/qemu-system-x86_64',
      }

      package { 'avahi':
        ensure => present;
      }

      service { 'avahi-daemon':
        ensure  => running,
        require => Package['avahi'];
      }

      Package['avahi'] ->
      Service['messagebus'] ->
      Service['avahi-daemon'] ->
      Service['libvirt']

      service { 'libvirt-guests':
        name       => 'libvirt-guests',
        enable     => false,
        ensure     => true,
        hasstatus  => false,
        hasrestart => false,
      }

      # From legacy params.pp
      $libvirt_type_kvm             = $::operatingsystem ? {
                                    redhat =>  'qemu-kvm-rhev',
                                    default => 'qemu-kvm',
                                  }
      $guestmount_package_name      = 'libguestfs-tools-c'

      # From legacy utilities.pp
      package { ['unzip', 'curl', 'euca2ools']:
        ensure => present
      }
      if !(defined(Package['parted'])) {
        package {'parted': ensure => 'present' }
      }

      package {$guestmount_package_name: ensure => present}
    }
    'Debian': {
      augeas { 'default-libvirt':
        context => '/files/etc/default/libvirt-bin',
        changes => "set libvirtd_opts '\"-l -d\"'",
        before  => Augeas['libvirt-conf'],
      }
      # From legacy params
      $libvirt_type_kvm             = 'qemu-kvm'
      $guestmount_package_name      = 'guestmount'
    }
  default: { fail("Unsupported osfamily: ${::osfamily}") }
  }

  augeas { 'libvirt-conf':
    context => '/files/etc/libvirt/libvirtd.conf',
    changes => [
      'set listen_tls 0',
      'set listen_tcp 1',
      'set auth_tcp none',
    ],
    notify  => Service['libvirt'],
  }

  $host_uuid=generate('/bin/sh', '-c', "uuidgen")

  augeas { 'libvirt-conf-uuid':
    context => '/files/etc/libvirt/libvirtd.conf',
    changes => [
      "set host_uuid $host_uuid",
    ],
    onlyif  => "match /files/etc/libvirt/libvirtd.conf/host_uuid size == 0",
    notify  => Service['libvirt'],
  }

  $memcached_addresses =  suffix($cache_server_ip, inline_template(":<%= @cache_server_port %>"))
  $notify_on_state_change = 'vm_and_task_state'

  class { 'nova':
      install_utilities      => false,
      ensure_package         => $::openstack_version['nova'],
      sql_connection         => $sql_connection,
      rpc_backend            => $rpc_backend,
      #FIXME(bogdando) we have to split amqp_hosts until all modules synced
      rabbit_hosts           => split($amqp_hosts, ','),
      rabbit_userid          => $amqp_user,
      rabbit_password        => $amqp_password,
      image_service          => 'nova.image.glance.GlanceImageService',
      glance_api_servers     => $glance_api_servers,
      verbose                => $verbose,
      debug                  => $debug,
      use_syslog             => $use_syslog,
      log_facility           => $syslog_log_facility,
      state_path             => $state_path,
      report_interval        => $nova_report_interval,
      service_down_time      => $nova_service_down_time,
      notify_on_state_change => $notify_on_state_change,
      memcached_servers      => $memcached_addresses,
      nova_shell             => '/bin/bash',
  }

  # From legacy init.pp
  if !($glance_api_servers) {
    # TODO this only supports setting a single address for the api server
    Nova_config <<| tag == "${::deployment_id}::${::environment}" and title == 'glance_api_servers' |>>
  }

  #Cinder setup
  $enabled_apis = 'metadata'

  if str2bool($::is_virtual) {
    $libvirt_cpu_mode = 'none'
  } else {
    $libvirt_cpu_mode = 'host-model'
  }
  # Install / configure nova-compute

  # From legacy ceilometer notifications for nova
  $instance_usage_audit = true
  $instance_usage_audit_period = 'hour'

  class { '::nova::compute':
    ensure_package                => $::openstack_version['nova'],
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $vncproxy_host,
    #NOTE(bogdando) default became true in 4.0.0 puppet-nova (was false)
    neutron_enabled               => false,
    instance_usage_audit          => $instance_usage_audit,
    instance_usage_audit_period   => $instance_usage_audit_period,
  }

  nova_config {
    'libvirt/live_migration_flag': value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST';
  }

  nova_config {
    'DEFAULT/cinder_catalog_info': value => 'volume:cinder:internalURL'
  }

  if $use_syslog {
    nova_config {
      'DEFAULT/use_syslog_rfc_format':  value => true;
    }
  }

  # Enable the file injection feature
  if !$::fuel_settings['storage']['images_ceph'] {
    if $::osfamily == 'RedHat' {
      nova_config { 'libvirt/inject_partition': value => '-1'; }
      }
    else {
      nova_config { 'libvirt/inject_partition': value => '1'; }
    }
  }

  # From legacy libvirt.pp
  if !($vncproxy_host) {
    warning("VNC is enabled and \$vncproxy_host must be specified nova::compute assumes that it can\
 collect the exported resource: Nova_config[novncproxy_base_url]")
    Nova_config <<| tag == "${::deployment_id}::${::environment}" and title == 'novncproxy_base_url' |>>
  }

  # Configure libvirt for nova-compute
  if !$::fuel_settings['storage']['images_ceph'] {
    class { 'nova::compute::libvirt':
      libvirt_virt_type       => $libvirt_type,
      libvirt_cpu_mode        => $libvirt_cpu_mode,
      libvirt_disk_cachemodes => ['"file=directsync"','"block=none"'],
      vncserver_listen        => $vncserver_listen,
    }
  } else {
    class { 'nova::compute::libvirt':
      libvirt_virt_type       => $libvirt_type,
      libvirt_cpu_mode        => $libvirt_cpu_mode,
      libvirt_disk_cachemodes => ['"network=writeback"','"block=none"'],
      vncserver_listen        => $vncserver_listen,
    }
  }

  # From legacy libvirt.pp
  if $::operatingsystem == 'Ubuntu' {

    package { 'cpufrequtils':
      ensure => present;
    }
    file { '/etc/default/cpufrequtils':
      content => "GOVERNOR=\"performance\" \n",
      require => Package['cpufrequtils'],
      notify  => Service['cpufrequtils'],
    }
    service { 'cpufrequtils':
      name   => 'cpufrequtils',
      enable => true,
      ensure => true,
    }
    Package<| title == 'cpufrequtils'|> ~> Service<| title == 'cpufrequtils'|>
    if !defined(Service['cpufrequtils']) {
      notify{ "Module ${module_name} cannot notify service cpufrequtils\
 on package update": }
    }
  }

  if $::operatingsystem == 'Centos' {
    package { 'cpufreq-init':
      ensure => present;
    }
  }

  include nova::params
  case $libvirt_type {
    'kvm': {
      package { $libvirt_type_kvm:
        ensure => present,
        before => Package[$::nova::params::compute_package_name],
      }
      case $::osfamily {
        'RedHat': {
          exec { '/etc/sysconfig/modules/kvm.modules':
            path      => '/sbin:/usr/sbin:/bin:/usr/bin',
            unless    => 'lsmod | grep -q kvm',
            require   => Package[$libvirt_type_kvm],
          }
        }
        'Debian': {
          service { 'qemu-kvm':
            ensure    => running,
            require   => Package[$libvirt_type_kvm],
            subscribe => Package[$libvirt_type_kvm],
          }
        }
        default: { fail("Unsupported osfamily: ${osfamily}") }
      }
    }
  }

  Service<| title == 'libvirt'|> ~> Service<| title == 'nova-compute'|>
  Package<| title == "nova-compute-${libvirt_type}"|> ~>
  Service<| title == 'nova-compute'|>
  if !defined(Service['nova-compute']) {
    notify{ "Module ${module_name} cannot notify service nova-compute\
on packages update": }
  }

  file_line { 'no_qemu_selinux':
    path    => '/etc/libvirt/qemu.conf',
    line    => 'security_driver="none"',
    require => Package[$::nova::params::libvirt_package_name],
    notify  => Service['libvirt']
  }

  nova_config {
    'DEFAULT/connection_type':  value => 'libvirt';
  }

  Package<| title == 'nova-compute'|> ~> Service<| title == 'nova-compute'|>
  if !defined(Service['nova-compute']) {
    notify{ "Module ${module_name} cannot notify service nova-compute\
 on packages update": }
  }

  Package<| title == 'libvirt'|> ~> Service<| title == 'libvirt'|>
  if !defined(Service['libvirt']) {
    notify{ "Module ${module_name} cannot notify service libvirt on package update": }
  }

  include nova::client

  # Ensure ssh clients are installed
  case $::osfamily {
    'Debian': { $scp_package='openssh-client' }
    'RedHat': { $scp_package='openssh-clients' }
    default: { fail("Unsupported osfamily: ${osfamily}") }
  }
  if !defined(Package[$scp_package]) {
    package { $scp_package:
      ensure => installed
    }
  }

  # From legacy init.pp
  nova_config { 'DEFAULT/allow_resize_to_same_host':  value => true; }

  # Install ssh keys and config file
  install_ssh_keys {'nova_ssh_key_for_migration':
    ensure           => present,
    user             => 'nova',
    private_key_path => $ssh_private_key,
    public_key_path  => $ssh_public_key,
    private_key_name => 'id_rsa',
    public_key_name  => 'id_rsa.pub',
    authorized_keys  => 'authorized_keys',
  } ->
  file { '/var/lib/nova/.ssh/config':
    ensure  => present,
    owner   => 'nova',
    group   => 'nova',
    mode    => '0600',
    content => "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n",
  }

  # configure ceilometer compute agent
  if ($ceilometer) {
    class { 'openstack::ceilometer':
      verbose                        => $verbose,
      debug                          => $debug,
      use_syslog                     => $use_syslog,
      syslog_log_facility            => $syslog_log_facility_ceilometer,
      amqp_hosts                     => $amqp_hosts,
      amqp_user                      => $amqp_user,
      amqp_password                  => $amqp_password,
      keystone_host                  => $service_endpoint,
      keystone_password              => $ceilometer_user_password,
      on_compute                     => true,
      metering_secret                => $ceilometer_metering_secret,
    }
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if $network_provider == 'nova' {

    if ! $fixed_range {
      fail('Must specify the fixed range when using nova-networks')
    }

    if $multi_host {
      include keystone::python

      case $::osfamily {
        'RedHat': {
          $pymemcache_package_name      = 'python-memcached'
        }
        'Debian': {
          $pymemcache_package_name      = 'python-memcache'
        }
        default: {
          fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
                module ${module_name} only support osfamily RedHat and Debian")
        }
      }
      if !defined(Package[$pymemcache_package_name]) {
        package { $pymemcache_package_name:
          ensure => present,
        } ->
        Nova::Generic_service <| title == 'api' |>
      }

      class { 'nova::api':
        ensure_package       => $::openstack_version['nova'],
        enabled              => true,
        admin_tenant_name    => 'services',
        admin_user           => 'nova',
        admin_password       => $nova_user_password,
        enabled_apis         => $enabled_apis,
        api_bind_address     => $internal_address,
        auth_host            => $service_endpoint,
        ratelimits           => $nova_rate_limits,
        # NOTE(bogdando) 1 api worker for compute node is enough
        osapi_compute_workers => 1,
      }

      if($::operatingsystem == 'Ubuntu') {
        tweaks::ubuntu_service_override { 'nova-api':
          package_name => 'nova-api',
        }
      }

      nova_config {
        'DEFAULT/multi_host':      value => 'True';
        'DEFAULT/send_arp_for_ha': value => 'True';
        'DEFAULT/metadata_host':   value => $internal_address;
      }

      if ! $public_interface {
        fail('public_interface must be defined for multi host compute nodes')
      }

      $enable_network_service = true

      if $auto_assign_floating_ip {
        nova_config { 'DEFAULT/auto_assign_floating_ip': value => 'True' }
      }
    } else {
      $enable_network_service = false

      nova_config {
        'DEFAULT/multi_host':      value => 'False';
        'DEFAULT/send_arp_for_ha': value => 'False';
      }
    }

    # From legacy network.pp
    if $network_manager !~ /VlanManager$/ {
      $config_overrides = delete($network_config, 'vlan_start')
    } else {
      $config_overrides = $network_config
    }

    # From legacy network.pp
    # I don't think this is applicable to Folsom...
    # If it is, the details will need changed. -jt
    if $network_manager == 'nova.network.neutron.manager.NeutronManager' {
      $parameters = { fixed_range      => $fixed_range,
                      public_interface => $public_interface,
                    }
      $resource_parameters = merge($_config_overrides, $parameters)
      $neutron_resource = { 'nova::network::neutron' => $resource_parameters }
      create_resources('class', $neutron_resource)
    }

  } else {

    # script called by qemu needs to manipulate the tap device
    file { '/etc/libvirt/qemu.conf':
      ensure => present,
      notify => Service['libvirt'],
      source => 'puppet:///modules/nova/libvirt_qemu.conf',
    }

    class { 'nova::compute::neutron':
      libvirt_vif_driver => $libvirt_vif_driver,
    }

    nova_config {
      'DEFAULT/linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
      'DEFAULT/linuxnet_ovs_integration_bridge': value => $neutron_integration_bridge;
    }

    augeas { 'sysctl-net.bridge.bridge-nf-call-arptables':
      context => '/files/etc/sysctl.conf',
      changes => "set net.bridge.bridge-nf-call-arptables '1'",
      before  => Service['libvirt'],
    }
    augeas { 'sysctl-net.bridge.bridge-nf-call-iptables':
      context => '/files/etc/sysctl.conf',
      changes => "set net.bridge.bridge-nf-call-iptables '1'",
      before  => Service['libvirt'],
    }
    augeas { 'sysctl-net.bridge.bridge-nf-call-ip6tables':
      context => '/files/etc/sysctl.conf',
      changes => "set net.bridge.bridge-nf-call-ip6tables '1'",
      before  => Service['libvirt'],
    }

  }

  ####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'nova-compute':
      package_name => "nova-compute-${libvirt_type}",
    }
    tweaks::ubuntu_service_override { 'nova-network':
      package_name => 'nova-network',
    }
    # Ceph rbd backend configures its override on its own
    if !$::fuel_settings['storage']['volumes_ceph'] {
      tweaks::ubuntu_service_override { 'cinder-volume':
        package_name => 'cinder-volume',
      }
    }
  }


  ######## [Nova|Neutron] Network ########
  if $network_provider == 'neutron' {

    # FIXME(xarses) Nearly everything between here and the class
    # should be moved into osnaily or nailgun but will stay here
    # in the interim.
    $neutron_settings = $::fuel_settings['quantum_settings']

    $pnets = $neutron_settings['L2']['phys_nets']
    if $pnets['physnet1'] {
      $physnet1 = "physnet1:${pnets['physnet1']['bridge']}"
      notify{ $physnet1:}
    }
    if $pnets['physnet2'] {
      $physnet2 = "physnet2:${pnets['physnet2']['bridge']}"
      notify{ $physnet2:}
      if $pnets['physnet2']['vlan_range'] {
        $vlan_range = ["physnet2:${pnets['physnet2']['vlan_range']}"]
        $fallback = split($pnets['physnet2']['vlan_range'], ':')
        notify{ $vlan_range:}
      }
    } else {
      $vlan_range = []
    }

    if $physnet1 and $physnet2 {
      $bridge_mappings = [$physnet1, $physnet2]
    } elsif $physnet1 {
      $bridge_mappings = [$physnet1]
    } elsif $physnet2 {
      $bridge_mappings = [$physnet2]
    } else {
      $bridge_mappings = []
    }

    if $neutron_settings['L2']['tunnel_id_ranges'] {
      $enable_tunneling = true
      $tunnel_id_ranges = [$neutron_settings['L2']['tunnel_id_ranges']]
    } else {
      $enable_tunneling = false
      $tunnel_id_ranges = []
    }
    notify{ $tunnel_id_ranges:}
    if $neutron_settings['L2']['mechanism_drivers'] {
        $mechanism_drivers = split($neutron_settings['L2']['mechanism_drivers'], ',')
    } else {
        $mechanism_drivers = ['openvswitch']
    }

    if $neutron_settings['L2']['provider'] == 'ovs' {
      $core_plugin      = 'openvswitch'
      $agent            = 'ovs'
    } elsif $neutron_settings['L2']['provider'] == 'nsx' {
      # do nothing because nsx has its own neutron's agent
      # which will be installed in module plugin_neutronnsx
    } else {
      # by default we use ML2 plugin
      $core_plugin      = 'neutron.plugins.ml2.plugin.Ml2Plugin'
      $agent            = 'ml2-ovs'
    }
  }


  class { 'openstack::network':
    network_provider  => $network_provider,
    agents            => [$agent],
    public_address    => $public_address,
    internal_address  => $internal_address,
    admin_address     => $admin_address,
    nova_neutron      => true,

    base_mac          => $base_mac,
    core_plugin       => $core_plugin,
    service_plugins   => undef,

    # ovs
    mechanism_drivers   => $mechanism_drivers,
    local_ip            => $internal_address,
    bridge_mappings     => $bridge_mappings,
    network_vlan_ranges => $vlan_range,
    enable_tunneling    => $enable_tunneling,
    tunnel_id_ranges    => $tunnel_id_ranges,

    verbose             => $verbose,
    debug               => $debug,
    use_syslog          => $use_syslog,
    syslog_log_facility => $syslog_log_facility_neutron,

    # queue settings
    queue_provider => $queue_provider,
    amqp_hosts     => [$amqp_hosts],
    amqp_user      => $amqp_user,
    amqp_password  => $amqp_password,

    # keystone
    admin_password => $neutron_user_password,
    auth_url       => "http://${service_endpoint}:35357/v2.0",
    neutron_url    => "http://${service_endpoint}:9696",

    # metadata
    shared_secret  => undef,

    integration_bridge => $neutron_integration_bridge,

    # nova settings
    private_interface => $private_interface,
    public_interface  => $public_interface,
    fixed_range       => $fixed_range,
    floating_range    => $floating_range,
    network_manager   => $network_manager,
    network_config    => $config_overrides,
    create_networks   => $create_networks,
    num_networks      => $num_networks,
    network_size      => $network_size,
    nameservers       => $nameservers,
    enable_nova_net   => $enable_network_service,
  }
}
