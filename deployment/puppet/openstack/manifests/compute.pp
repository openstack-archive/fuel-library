#
# == Class: openstack::compute
#
# Manifest to install/configure nova-compute
#
# === Parameters
#
# See params.pp
#
# [internal_address] Internal address used for management. Required.
#   Defaults to false.
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
#   Optional. Defaults to false.
#   network settings. Optioal. Defaults to {}
# [sql_connection] SQL connection information. Optional. Defaults to false
#   which indicates that exported resources will be used to determine connection
#   information.
#  [amqp_hosts] RabbitMQ hosts or false. Optional. Defaults to false.
#  [amqp_user] RabbitMQ user. Optional. Defaults to 'nova',
#  [amqp_password] RabbitMQ password. Optional. Defaults to  'rabbit_pw',
#  [glance_api_servers] List of glance api servers of the form HOST:PORT
#    delimited by ':'. False indicates that the resource should be collected.
#    Optional. Defaults to false,
#  [libvirt_type] Underlying libvirt supported hypervisor.
#    Optional. Defaults to 'kvm',
#  [vncproxy_protocol] Protocol to use for access vnc proxy. Optional.
#    Defaults to 'http'.
#  [vncproxy_host] Host that serves as vnc proxy. Optional.
#    Defaults to false. False indicates that a vnc proxy should not be configured.
# [verbose] Rather to print more verbose (INFO+) output. If non verbose and non debug. Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option. Optional. Defaults to false.
# [use_syslog] Rather or not service should log to syslog. Optional.
# [use_stderr] Rather or not service should log to stderr. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [ssh_private_key] path to private ssh key temporary location on this server where it was uploaded or generated
# [ssh_public_key] path to public ssh key temporary location on this server where it was uploaded or generated
# [compute_driver] Driver to use for controlling virtualization.
#
# class { 'openstack::nova::compute':
#   internal_address   => '192.168.2.2',
#   vncproxy_host      => '192.168.1.1',
# }

class openstack::compute (
  # Required Network
  $internal_address,
  # Required Nova
  # RPC
  $rpc_backend                    = 'rabbit',
  $amqp_hosts                     = false,
  $amqp_user                      = 'nova',
  $amqp_password                  = 'rabbit_pw',
  $glance_api_servers             = undef,
  $libvirt_type                   = 'kvm',
  # FIXME(bogdando) remove after fixed upstream https://review.openstack.org/131710
  $host_uuid                      = undef,
  # VNC
  $vncproxy_protocol              = 'http',
  $vncproxy_host                  = undef,
  $vncserver_listen               = '0.0.0.0',
  $migration_support              = false,
  # General
  $enabled                        = true,
  # nova compute configuration parameters
  $nova_hash                      = {},
  $use_huge_pages                 = false,
  $vcpu_pin_set                   = undef,
  $verbose                        = false,
  $debug                          = false,
  $ssh_private_key                = '/var/lib/astute/nova/nova',
  $ssh_public_key                 = '/var/lib/astute/nova/nova.pub',
  $cache_server_ip                = ['127.0.0.1'],
  $cache_server_port              = '11211',
  $pci_passthrough                = undef,
  $use_syslog                     = false,
  $use_stderr                     = true,
  $syslog_log_facility            = 'LOG_LOCAL6',
  $nova_report_interval           = '10',
  $nova_service_down_time         = '60',
  $state_path                     = '/var/lib/nova',
  $notification_driver            = 'noop',
  $storage_hash                   = {},
  $compute_driver                 = 'libvirt.LibvirtDriver',
  $config_drive_format            = undef,
  $network_device_mtu             = '65000',
) {

  include ::nova::params

  case $::osfamily {
    'RedHat': {
      # TODO(aschultz): this is actually handled by ::nova::migration::libvirt
      # when you include nova::compute::libvirt so we can probably remove this
      # after it has been verified
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
      $libvirt_type_kvm             = 'qemu-kvm'
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
      # TODO(aschultz): this is actually handled by ::nova::migration::libvirt
      # when you include nova::compute::libvirt so we can probably remove this
      # after it has been verified
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

  # TODO(aschultz): this is actually handled by ::nova::migration::libvirt
  # when you include nova::compute::libvirt so we can probably remove this
  # after it has been verified
  augeas { 'libvirt-conf':
    context => '/files/etc/libvirt/libvirtd.conf',
    changes => [
      'set listen_tls 0',
      'set listen_tcp 1',
      'set auth_tcp none',
    ],
    notify  => Service['libvirt'],
  }

  augeas { 'libvirt-conf-uuid':
    context => '/files/etc/libvirt/libvirtd.conf',
    changes => [
      "set host_uuid $host_uuid",
    ],
    onlyif  => "match /files/etc/libvirt/libvirtd.conf/host_uuid size == 0",
    notify  => Service['libvirt'],
  }

  if $::osfamily == 'Debian' {
    if $use_huge_pages {
      $qemu_hugepages_value = 'set KVM_HUGEPAGES 1'
    } else {
      $qemu_hugepages_value = 'rm KVM_HUGEPAGES'
    }
    augeas { 'qemu_hugepages':
      context => '/files/etc/default/qemu-kvm',
      changes => $qemu_hugepages_value,
      notify  => Service['libvirt'],
    }

    Augeas['qemu_hugepages'] ~> Service<| title == 'qemu-kvm'|>
    Service<| title == 'qemu-kvm'|> -> Service<| title == 'libvirt'|>
  }

  if ($::operatingsystem == 'Ubuntu') and ($libvirt_type =='kvm') {
    # TODO(skolekonov): Remove when LP#1057024 has been resolved.
    # https://bugs.launchpad.net/ubuntu/+source/qemu-kvm/+bug/1057024
    file { '/dev/kvm':
      ensure => present,
      group  => 'kvm',
      mode   => '0660',
    }
    Service<| title == 'qemu-kvm'|> -> File['/dev/kvm']
  }

  $memcached_addresses =  suffix($cache_server_ip, inline_template(":<%= @cache_server_port %>"))
  $notify_on_state_change = 'vm_and_task_state'

  if $debug {
    class { 'nova::logging':
      default_log_levels => {
        'oslo.messaging' => 'DEBUG',
      }
    }
  }

  class { 'nova':
    install_utilities      => false,
    rpc_backend            => $rpc_backend,
    #FIXME(bogdando) we have to split amqp_hosts until all modules synced
    rabbit_hosts           => split($amqp_hosts, ','),
    rabbit_userid          => $amqp_user,
    rabbit_password        => $amqp_password,
    kombu_reconnect_delay  => '5.0',
    image_service          => 'nova.image.glance.GlanceImageService',
    glance_api_servers     => $glance_api_servers,
    verbose                => $verbose,
    debug                  => $debug,
    use_syslog             => $use_syslog,
    use_stderr             => $use_stderr,
    log_facility           => $syslog_log_facility,
    state_path             => $state_path,
    report_interval        => $nova_report_interval,
    service_down_time      => $nova_service_down_time,
    notify_on_state_change => $notify_on_state_change,
    notification_driver    => $notification_driver,
    memcached_servers      => $memcached_addresses,
    cinder_catalog_info    => pick($nova_hash['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
  }

  Class['nova::logging'] -> Class['nova']

  class {'::nova::availability_zone':
    default_availability_zone => $nova_hash['default_availability_zone'],
    default_schedule_zone     => $nova_hash['default_schedule_zone'],
  }

  if str2bool($::is_virtual) {
    $libvirt_cpu_mode = 'none'
  } else {
    $libvirt_cpu_mode = 'host-model'
  }
  # Install / configure nova-compute

  # From legacy ceilometer notifications for nova
  $instance_usage_audit = true
  $instance_usage_audit_period = 'hour'

  ####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'nova-compute':
      package_name => "nova-compute-${libvirt_type}",
    }
  }

  class { '::nova::compute':
    enabled                       => $enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_protocol             => $vncproxy_protocol,
    vncproxy_host                 => $vncproxy_host,
    vncproxy_port                 => $nova_hash['vncproxy_port'],
    force_config_drive            => $nova_hash['force_config_drive'],
    pci_passthrough               => $pci_passthrough,
    network_device_mtu            => $network_device_mtu,
    instance_usage_audit          => $instance_usage_audit,
    instance_usage_audit_period   => $instance_usage_audit_period,
    reserved_host_memory          => $nova_hash['reserved_host_memory'],
    config_drive_format           => $config_drive_format,
    allow_resize_to_same_host     => true,
    vcpu_pin_set                  => $vcpu_pin_set,
  }

  nova_config {
    'libvirt/live_migration_flag':  value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST';
    'libvirt/block_migration_flag': value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_NON_SHARED_INC';
    'DEFAULT/connection_type':      value => 'libvirt';
  }

  if $use_syslog {
    nova_config {
      'DEFAULT/use_syslog_rfc_format':  value => true;
    }
  }

  # The default value for inject_partition is -2, so it will be disabled
  # when we use Ceph for ephemeral storage or for Cinder. We only need to
  # modify the libvirt_disk_cachemodes in that case.
  if ($storage_hash['ephemeral_ceph'] or $storage_hash['volumes_ceph']) {
    $disk_cachemodes = ['"network=writeback,block=none"']
    $libvirt_inject_partition = '-2'
  } else {
    if $::osfamily == 'RedHat' {
      $libvirt_inject_partition = '-1'
    } else {
      # Enable module by default on each compute node
      k_mod {'nbd':
        ensure => 'present'
      }
      file_line {'nbd_on_boot':
        path => '/etc/modules',
        line => 'nbd',
      }
      $libvirt_inject_partition = '1'
    }
    $disk_cachemodes = ['"file=directsync,block=none"']
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_virt_type                          => $libvirt_type,
    libvirt_cpu_mode                           => $libvirt_cpu_mode,
    libvirt_disk_cachemodes                    => $disk_cachemodes,
    libvirt_inject_partition                   => $libvirt_inject_partition,
    vncserver_listen                           => $vncserver_listen,
    migration_support                          => $migration_support,
    remove_unused_original_minimum_age_seconds => pick($nova_hash['remove_unused_original_minimum_age_seconds'], '86400'),
    compute_driver                             => $compute_driver,
    libvirt_service_name                       => $::nova::params::libvirt_service_name,
  }

  # From legacy libvirt.pp
  if $::operatingsystem == 'Ubuntu' {
    package { 'cpufrequtils':
      ensure => present;
    }
    file { '/etc/default/cpufrequtils':
      content => "GOVERNOR=\"performance\"\n",
      require => Package['cpufrequtils'],
      notify  => Service['cpufrequtils'],
    }
    service { 'cpufrequtils':
      ensure    => 'running',
      enable    => true,
      status    => '/bin/true',
    }

    Package<| title == 'cpufrequtils'|> ~> Service<| title == 'cpufrequtils'|>
    if !defined(Service['cpufrequtils']) {
      notify{ "Module ${module_name} cannot notify service cpufrequtils on package update": }
    }
  }

  package { $libvirt_type_kvm:
    ensure => present,
    before => Package[$::nova::params::compute_package_name],
  }

  case $::osfamily {
    'RedHat': {
      if $libvirt_type =='kvm' {
        exec { '/etc/sysconfig/modules/kvm.modules':
          path      => '/sbin:/usr/sbin:/bin:/usr/bin',
          unless    => 'lsmod | grep -q kvm',
          require   => Package[$libvirt_type_kvm],
        }
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

  Service<| title == 'libvirt'|> ~> Service<| title == 'nova-compute'|>
  Package<| title == "nova-compute-${libvirt_type}"|> ~>
  Service<| title == 'nova-compute'|>

  case $::osfamily {
    'RedHat': {
      file_line { 'qemu_selinux':
        path    => '/etc/libvirt/qemu.conf',
        line    => 'security_driver = "selinux"',
        require => Package[$::nova::params::libvirt_package_name],
        notify  => Service['libvirt']
      }
    }
    'Debian': {
      file_line { 'qemu_apparmor':
        path    => '/etc/libvirt/qemu.conf',
        line    => 'security_driver = "apparmor"',
        require => Package[$::nova::params::libvirt_package_name],
        notify  => Service['libvirt']
      }

      file_line { 'apparmor_libvirtd':
        path  => '/etc/apparmor.d/usr.sbin.libvirtd',
        line  => "#  unix, # shouldn't be used for libvirt/qemu",
        match => '^[#[:space:]]*unix',
      }

      exec { 'refresh_apparmor':
        refreshonly => true,
        command     => '/sbin/apparmor_parser -r /etc/apparmor.d/usr.sbin.libvirtd',
        subscribe   => File_line['apparmor_libvirtd'],
      }
    }
  }

  Package<| title == 'nova-compute'|> ~> Service<| title == 'nova-compute'|>
  if !defined(Service['nova-compute']) {
    notify{ "Module ${module_name} cannot notify service nova-compute on packages update": }
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

}
