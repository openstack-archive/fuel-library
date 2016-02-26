notice('MODULAR: compute.pp')

$network_scheme = hiera_hash('network_scheme', {})
$override_configuration = hiera_hash('configuration', {})
$network_metadata = hiera_hash('network_metadata', {})
prepare_network_config($network_scheme)

# override nova options
override_resources { 'nova_config':
  data => $override_configuration['nova_config']
}

# override nova-api options
override_resources { 'nova_paste_api_ini':
  data => $override_configuration['nova_paste_api_ini']
}

Override_resources <||> ~> Service <| tag == 'nova-service' |>

# Pulling hiera
$compute_hash                   = hiera_hash('compute', {})
$public_vip                     = hiera('public_vip')
$management_vip                 = hiera('management_vip')
$database_vip                   = hiera('database_vip')
$primary_controller             = hiera('primary_controller')
$use_neutron                    = hiera('use_neutron', false)
$sahara_hash                    = hiera('sahara', {})
$verbose                        = pick($compute_hash['verbose'], true)
$debug                          = pick($compute_hash['debug'], hiera('debug', true))
$use_monit                      = false
$storage_hash                   = hiera_hash('storage_hash', {})
$vcenter_hash                   = hiera('vcenter', {})
$hiera_nova_hash                = hiera_hash('nova_hash', {})
$nova_custom_hash               = hiera_hash('nova_custom_hash', {})
$rabbit_hash                    = hiera_hash('rabbit_hash', {})
$glance_hash                    = hiera_hash('glance_hash', {})
$keystone_hash                  = hiera_hash('keystone_hash', {})
$swift_hash                     = hiera_hash('swift_hash', {})
$ceilometer_hash                = hiera_hash('ceilometer_hash',{})
$access_hash                    = hiera('access', {})
$swift_proxies                  = hiera('swift_proxies')
$swift_master_role              = hiera('swift_master_role', 'primary-controller')
$neutron_mellanox               = hiera('neutron_mellanox', false)
$syslog_hash                    = hiera('syslog', {})
$base_syslog_hash               = hiera('base_syslog', {})
$use_syslog                     = hiera('use_syslog', true)
$use_stderr                     = hiera('use_stderr', false)
$syslog_log_facility            = hiera('syslog_log_facility_nova','LOG_LOCAL6')
$nova_report_interval           = hiera('nova_report_interval')
$nova_service_down_time         = hiera('nova_service_down_time')
$config_drive_format            = 'vfat'
$public_ssl_hash                = hiera('public_ssl')
$ssl_hash                       = hiera_hash('use_ssl', {})
$ssh_private_key                = '/var/lib/astute/nova/nova'
$ssh_public_key                 = '/var/lib/astute/nova/nova.pub'
$libvirt_type                   = hiera('libvirt_type', undef)

# FIXME(bogdando) remove after fixed upstream https://review.openstack.org/131710
$host_uuid                      = hiera('host_uuid', generate('/bin/sh', '-c', 'uuidgen'))


$glance_protocol                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
$glance_endpoint                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', [hiera('glance_endpoint', $management_vip)])
$glance_internal_ssl            = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'usage', false)
if $glance_internal_ssl {
  $glance_api_servers = "${glance_protocol}://${glance_endpoint}:9292"
} else {
  $glance_api_servers = hiera('glance_api_servers', "${management_vip}:9292")
}

$vncproxy_protocol                      = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'protocol', [$nova_hash['vncproxy_protocol'], 'http'])
$vncproxy_host                          = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'hostname', [$public_vip])

$block_device_allocate_retries          = hiera('block_device_allocate_retries', 300)
$block_device_allocate_retries_interval = hiera('block_device_allocate_retries_interval', 3)

# TODO: openstack_version is confusing, there's such string var in hiera and hardcoded hash
$hiera_openstack_version = hiera('openstack_version')
$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

# Do the stuff
if $neutron_mellanox {
  $mellanox_mode = $neutron_mellanox['plugin']
} else {
  $mellanox_mode = 'disabled'
}

if $use_neutron {
  $novanetwork_params        = {}
  $network_provider          = 'neutron'
  $neutron_config            = hiera_hash('quantum_settings')
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
} else {
  $network_provider   = 'nova'
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
}

if $primary_controller {
  if ($mellanox_mode == 'ethernet') {
    $test_vm_pkg = 'cirros-testvm-mellanox'
  } else {
    $test_vm_pkg = 'cirros-testvm'
  }
  package { 'cirros-testvm' :
    ensure => 'installed',
    name   => $test_vm_pkg,
  }
}

$floating_hash = {}

##CALCULATED PARAMETERS

$memcached_server = hiera('memcached_addresses')
$memcached_port   = hiera('memcache_server_port', '11211')
$memcached_addresses =  suffix($memcached_server, inline_template(":<%= @memcached_port %>"))


# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

if ($storage_hash['volumes_lvm']) {
  nova_config { 'keymgr/fixed_key':
    value => $cinder_hash[fixed_key];
  }
}

# Get reserved host memory straight value if we've ceph neighbor
$r_hostmem = roles_include(['ceph-osd']) ? {
  true  => min(max(floor($::memorysize_mb*0.2), 512), 1536),
  false => undef,
}

# NOTE(bogdando) for controller nodes running Corosync with Pacemaker
#   we delegate all of the monitor functions to RA instead of monit.
if roles_include(['controller', 'primary-controller']) {
  $use_monit_real = false
} else {
  $use_monit_real = $use_monit
}

$mirror_type = 'external'
Exec { logoutput => true }

include ::osnailyfacter::test_compute

if ($::mellanox_mode == 'ethernet') {
  $neutron_private_net = pick($neutron_config['default_private_net'], 'net04')
  $physnet = $neutron_config['predefined_networks'][$neutron_private_net]['L2']['physnet']
  class { '::mellanox_openstack::compute':
    physnet => $physnet,
    physifc => $neutron_mellanox['physical_port'],
  }
}


$nova_hash = merge({ 'reserved_host_memory' => $r_hostmem }, $hiera_nova_hash)

# Required for fping API extension, see LP#1486404
ensure_packages('fping')

$nova_config_hash = {
  'DEFAULT/resume_guests_state_on_host_boot'       => { value => hiera('resume_guests_state_on_host_boot', 'False') },
  'DEFAULT/use_cow_images'                         => { value => hiera('use_cow_images', 'True') },
  'DEFAULT/block_device_allocate_retries'          => { value => $block_device_allocate_retries },
  'DEFAULT/block_device_allocate_retries_interval' => { value => $block_device_allocate_retries_interval },
  'libvirt/libvirt_inject_key'                     => { value => true },
  'libvirt/libvirt_inject_password'                => { value => true },
}

$nova_complete_hash = merge($nova_config_hash, $nova_custom_hash)

class {'::nova::config':
  nova_config => $nova_complete_hash,
}

# Configure monit watchdogs
# FIXME(bogdando) replace service_path and action to systemd, once supported
if $use_monit_real {

  # Configure service names for monit watchdogs and 'service' system path
  # FIXME(bogdando) replace service_path to systemd, once supported
  include ::nova::params
  $nova_compute_name   = $::nova::params::compute_service_name
  $nova_api_name       = $::nova::params::api_service_name
  $nova_network_name   = $::nova::params::network_service_name
  $ovs_vswitchd_name   = $::l23network::params::ovs_service_name
  case $::osfamily {
    'RedHat' : {
      $service_path   = '/sbin/service'
    }
    'Debian' : {
      $service_path    = '/usr/sbin/service'
    }
    default  : {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }

  monit::check::process { $nova_compute_name :
    ensure        => running,
    matching      => '/usr/bin/python /usr/bin/nova-compute',
    program_start => "${service_path} ${nova_compute_name} restart",
    program_stop  => "${service_path} ${nova_compute_name} stop",
    pidfile       => false,
  }
  if $use_neutron {
    monit::check::process { $ovs_vswitchd_name :
      ensure        => running,
      program_start => "${service_path} ${ovs_vswitchd_name} restart",
      program_stop  => "${service_path} ${ovs_vswitchd_name} stop",
      pidfile       => '/var/run/openvswitch/ovs-vswitchd.pid',
    }
  } else {
    monit::check::process { $nova_network_name :
      ensure        => running,
      matching      => '/usr/bin/python /usr/bin/nova-network',
      program_start => "${service_path} ${nova_network_name} restart",
      program_stop  => "${service_path} ${nova_network_name} stop",
      pidfile       => false,
    }
    monit::check::process { $nova_api_name :
      ensure        => running,
      matching      => '/usr/bin/python /usr/bin/nova-api',
      program_start => "${service_path} ${nova_api_name} restart",
      program_stop  => "${service_path} ${nova_api_name} stop",
      pidfile       => false,
    }
  }
}

# Below here was imported from ::openstack::compute

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

# FIXME(bogdando) remove after fixed upstream https://review.openstack.org/131710
augeas { 'libvirt-conf-uuid':
  context => '/files/etc/libvirt/libvirtd.conf',
  changes => [
    "set host_uuid $host_uuid",
  ],
  onlyif  => "match /files/etc/libvirt/libvirtd.conf/host_uuid size == 0",
  notify  => Service['libvirt'],
}

$notify_on_state_change = 'vm_and_task_state'

class { 'nova':
  install_utilities      => false,
  ensure_package         => $::openstack_version['nova'],
  rpc_backend            => 'nova.openstack.common.rpc.impl_kombu',
  #FIXME(bogdando) we have to split amqp_hosts until all modules synced
  rabbit_hosts           => split(hiera('amqp_hosts',''), ','),
  rabbit_userid          => pick($rabbit_hash['user'], 'nova'),
  rabbit_password        => rabbit_hash['password'],
  kombu_reconnect_delay  => '5.0',
  image_service          => 'nova.image.glance.GlanceImageService',
  glance_api_servers     => $glance_api_servers,
  verbose                => $verbose,
  debug                  => $debug,
  use_syslog             => $use_syslog,
  use_stderr             => $use_stderr,
  log_facility           => $syslog_log_facility,
  state_path             => $nova_hash[state_path],
  report_interval        => $nova_report_interval,
  service_down_time      => $nova_service_down_time,
  notify_on_state_change => $notify_on_state_change,
  notification_driver    => $ceilometer_hash['notification_driver'],
  memcached_servers      => $memcached_addresses,
  cinder_catalog_info    => pick($nova_hash['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
}

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

# NOTE(bogdando) deploy compute node with disabled nova-compute
#   service #LP1398817. The orchestration will start and enable it back
#   after the deployment is done.
# FIXME(bogdando) This should be changed once the host aggregates implemented, bp disable-new-computes

class { '::nova::compute':
  ensure_package                => $::openstack_version['nova'],
  enabled                       => false,
  vnc_enabled                   => true,
  vncserver_proxyclient_address => $get_network_role_property('nova/api', 'ipaddr'),
  vncproxy_protocol             => $vncproxy_protocol,
  vncproxy_host                 => $vncproxy_host,
  vncproxy_port                 => $nova_hash['vncproxy_port'],
  force_config_drive            => $nova_hash['force_config_drive'],
  #NOTE(bogdando) default became true in 4.0.0 puppet-nova (was false)
  neutron_enabled               => ($network_provider == 'neutron'),
  install_bridge_utils          => false,
  network_device_mtu            => '65000',
  instance_usage_audit          => $instance_usage_audit,
  instance_usage_audit_period   => $instance_usage_audit_period,
  reserved_host_memory          => $nova_hash['reserved_host_memory'],
  config_drive_format           => $config_drive_format,
  allow_resize_to_same_host     => true,
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
  vncserver_listen                           => '0.0.0.0',
  migration_support                          => true,
  remove_unused_original_minimum_age_seconds => pick($nova_hash['remove_unused_original_minimum_age_seconds'], '86400'),
  compute_driver                             => 'libvirt.LibvirtDriver',
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

if $::operatingsystem == 'Centos' {
  package { 'cpufreq-init':
    ensure => present;
  }
}

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


# vim: set ts=2 sw=2 et :
