class openstack_tasks::roles::compute {

  notice('MODULAR: roles/compute.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  $override_configuration = hiera_hash('configuration', {})
  $network_metadata = hiera_hash('network_metadata', {})
  $nova_report_interval = hiera('nova_report_interval', '60')
  $nova_service_down_time = hiera('nova_service_down_time', '180')
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
  $mp_hash                        = hiera('mp')
  $verbose                        = pick($compute_hash['verbose'], true)
  $debug                          = pick($compute_hash['debug'], hiera('debug', true))
  $storage_hash                   = hiera_hash('storage', {})
  $nova_hash                      = hiera_hash('nova', {})
  $nova_custom_hash               = hiera_hash('nova_custom', {})
  $rabbit_hash                    = hiera_hash('rabbit', {})
  $cinder_hash                    = hiera_hash('cinder', {})
  $ceilometer_hash                = hiera_hash('ceilometer', {})
  $access_hash                    = hiera_hash('access', {})
  $neutron_mellanox               = hiera('neutron_mellanox', false)
  $syslog_hash                    = hiera_hash('syslog', {})
  $base_syslog_hash               = hiera_hash('base_syslog', {})
  $use_syslog                     = hiera('use_syslog', true)
  $use_stderr                     = hiera('use_stderr', false)
  $syslog_log_facility            = hiera('syslog_log_facility_nova','LOG_LOCAL6')
  $config_drive_format            = pick($compute_hash['config_drive_format'], 'vfat')
  $public_ssl_hash                = hiera_hash('public_ssl')
  $ssl_hash                       = hiera_hash('use_ssl', {})
  $node_hash                      = hiera_hash('node', {})
  $use_huge_pages                 = pick($node_hash['nova_hugepages_enabled'], false)
  $allocated_hugepages            = parsejson($::allocated_hugepages)
  $use_2m_huge_pages              = $allocated_hugepages['2M']
  $use_1g_huge_pages              = $allocated_hugepages['1G']
  $libvirt_type                   = hiera('libvirt_type', undef)
  $kombu_compression              = hiera('kombu_compression', '')

  $dpdk_config                    = hiera_hash('dpdk', {})
  $enable_dpdk                    = pick($dpdk_config['enabled'], false)
  if $enable_dpdk {
    # LP 1533876
    $network_device_mtu = false
  } else {
    $network_device_mtu = 65000
  }

  # get glance api servers list
  $glance_endpoint_default        = hiera('glance_endpoint', $management_vip)
  $glance_protocol                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
  $glance_endpoint                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', $glance_endpoint_default)
  $glance_api_servers             = hiera('glance_api_servers', "${glance_protocol}://${glance_endpoint}:9292")

  $vncproxy_protocol                      = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'protocol', [$nova_hash['vncproxy_protocol'], 'http'])
  $vncproxy_host                          = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'hostname', [$public_vip])

  $block_device_allocate_retries          = hiera('block_device_allocate_retries', 300)
  $block_device_allocate_retries_interval = hiera('block_device_allocate_retries_interval', 3)

  $rpc_backend = hiera('queue_provider', 'rabbit')

  # FIXME(xarses) Should be removed after
  # https://bugs.launchpad.net/fuel/+bug/1555284
  if $rpc_backend == 'rabbitmq' {
    $rpc_backend_real = 'rabbit'
  } else {
    $rpc_backend_real = $rpc_backend
  }

  # Do the stuff
  if $neutron_mellanox {
    $mellanox_mode = $neutron_mellanox['plugin']
  } else {
    $mellanox_mode = 'disabled'
  }

  include ::osnailyfacter::test_compute

  if ($::mellanox_mode == 'ethernet') {
    $neutron_config      = hiera_hash('quantum_settings')
    $neutron_private_net = pick($neutron_config['default_private_net'], 'net04')
    $physnet             = $neutron_config['predefined_networks'][$neutron_private_net]['L2']['physnet']
    class { '::mellanox_openstack::compute':
      physnet => $physnet,
      physifc => $neutron_mellanox['physical_port'],
    }
  }

  $floating_hash = {}

  ##CALCULATED PARAMETERS

  # TODO(xarses): Wait Nova compute uses memcache?
  $cache_server_ip     = hiera('memcached_addresses')
  $cache_server_port   = hiera('memcache_server_port', '11211')
  $memcached_addresses =  suffix($cache_server_ip, inline_template(':<%= @cache_server_port %>'))

  # TODO(xarses): We need to validate this is needed
  if ($storage_hash['volumes_lvm']) {
    nova_config { 'keymgr/fixed_key':
      value => $cinder_hash[fixed_key];
    }
  }

  # Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
    $use_swift = true
  } else {
    $use_swift = false
  }

  # Get reserved host memory straight value if we've ceph neighbor
  $r_hostmem = roles_include(['ceph-osd']) ? {
    true  => min(max(floor($::memorysize_mb*0.2), 512), 1536),
    false => undef,
  }

  $mirror_type = 'external'
  Exec { logoutput => true }

  $nova_hash_real = merge({ 'reserved_host_memory' => $r_hostmem }, $nova_hash)

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

  class { '::nova::config':
    nova_config => $nova_complete_hash,
  }

  ########################################################################

  include ::nova::params

  case $::osfamily {
    'RedHat': {
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

      # From legacy params
      $libvirt_type_kvm             = 'qemu-kvm'
      $guestmount_package_name      = 'guestmount'
    }
  default: { fail("Unsupported osfamily: ${::osfamily}") }
  }

  if $::osfamily == 'Debian' {
    if $use_huge_pages {
      if $use_1g_huge_pages {
        $hugepages_1g_opts_ensure = 'present'
        file { '/mnt/hugepages_1GB':
          ensure  => 'directory',
          owner   => 'root',
          group   => 'kvm',
          mode    => '775',
          require => Package[$libvirt_type_kvm],
        }
        exec { 'mount_hugetlbfs_1g':
          command  => 'mount -t hugetlbfs hugetlbfs-kvm -o mode=775,gid=kvm,pagesize=1GB /mnt/hugepages_1GB',
          unless   => 'grep -q /mnt/hugepages_1GB /proc/mounts',
          path     => '/usr/sbin:/usr/bin:/sbin:/bin',
          require  => File['/mnt/hugepages_1GB'],
        }
        if $use_2m_huge_pages {
          $libvirt_hugetlbfs_mount = 'hugetlbfs_mount = ["/run/hugepages/kvm", "/mnt/hugepages_1GB"]'
          $qemu_hugepages_value    = 'set KVM_HUGEPAGES 1'
        } else {
          $libvirt_hugetlbfs_mount = 'hugetlbfs_mount = "/mnt/hugepages_1GB"'
          $qemu_hugepages_value    = 'rm KVM_HUGEPAGES'
        }
      } else {
        $qemu_hugepages_value    = 'set KVM_HUGEPAGES 1'
        $libvirt_hugetlbfs_mount = 'hugetlbfs_mount = "/run/hugepages/kvm"'
      }
    } else {
      $qemu_hugepages_value     = 'rm KVM_HUGEPAGES'
      $libvirt_hugetlbfs_mount  = 'hugetlbfs_mount = ""'
      $hugepages_1g_opts_ensure = 'absent'
    }
    augeas { 'qemu_hugepages':
      context => '/files/etc/default/qemu-kvm',
      changes => $qemu_hugepages_value,
      notify  => Service['libvirt'],
    }
    file_line { 'libvirt_hugetlbfs_mount':
      path    => '/etc/libvirt/qemu.conf',
      line    => $libvirt_hugetlbfs_mount,
      match   => '^hugetlbfs_mount =.*$',
      require => Package[$::nova::params::libvirt_package_name],
      notify  => Service['libvirt'],
    }
    file_line { 'libvirt_1g_hugepages_apparmor':
      path    => '/etc/apparmor.d/abstractions/libvirt-qemu',
      after   => 'owner "/run/hugepages/kvm/libvirt/qemu/',
      line    => '  owner "/mnt/hugepages_1GB/libvirt/qemu/**" rw,',
      require => Package[$::nova::params::libvirt_package_name],
      notify  => Exec['refresh_apparmor'],
      ensure  => $hugepages_1g_opts_ensure,
    }
    file_line { '1g_hugepages_fstab':
      path   => '/etc/fstab',
      line   => 'hugetlbfs-kvm /mnt/hugepages_1GB hugetlbfs mode=775,gid=kvm,pagesize=1GB 0 0',
      ensure => $hugepages_1g_opts_ensure,
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

  $notify_on_state_change = 'vm_and_task_state'

  if $debug {
    class { '::nova::logging':
      default_log_levels => {
        'oslo.messaging' => 'DEBUG',
      }
    }
  }

  class { '::nova':
    rpc_backend            => $rpc_backend_real,
    #FIXME(bogdando) we have to split amqp_hosts until all modules synced
    rabbit_hosts           => split(hiera('amqp_hosts',''), ','),
    rabbit_userid          => pick($rabbit_hash['user'], 'nova'),
    rabbit_password        => $rabbit_hash['password'],
    glance_api_servers     => $glance_api_servers,
    verbose                => $verbose,
    debug                  => $debug,
    use_syslog             => $use_syslog,
    use_stderr             => $use_stderr,
    log_facility           => $syslog_log_facility,
    state_path             => $nova_hash_real['state_path'],
    report_interval        => $nova_report_interval,
    service_down_time      => $nova_service_down_time,
    notify_on_state_change => $notify_on_state_change,
    notification_driver    => $ceilometer_hash['notification_driver'],
    memcached_servers      => $memcached_addresses,
    cinder_catalog_info    => pick($nova_hash_real['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
  }

  class { '::nova::availability_zone':
    default_availability_zone => $nova_hash_real['default_availability_zone'],
    default_schedule_zone     => $nova_hash_real['default_schedule_zone'],
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

    # TODO(aschultz): work around until https://review.openstack.org/#/c/306677/
    # lands.
    if $::os_package_type == 'ubuntu' {
      ensure_resource('service', ['virtlogd','virtlockd'], {
        ensure => running,
        enable => true,
        require => Package[$::nova::params::libvirt_package_name],
        before => Service['libvirt']
      })
    }
  }

  # NOTE(bogdando) deploy compute node with disabled nova-compute
  #   service #LP1398817. The orchestration will start and enable it back
  #   after the deployment is done.
  # FIXME(bogdando) This should be changed once the host aggregates implemented, bp disable-new-computes
  class { '::nova::compute':
    enabled                       => false,
    vncserver_proxyclient_address => get_network_role_property('nova/api', 'ipaddr'),
    vncproxy_protocol             => $vncproxy_protocol,
    vncproxy_host                 => $vncproxy_host,
    vncproxy_port                 => $nova_hash_real['vncproxy_port'],
    force_config_drive            => $nova_hash_real['force_config_drive'],
    pci_passthrough               => nic_whitelist_to_json(get_nic_passthrough_whitelist('sriov')),
    network_device_mtu            => $network_device_mtu,
    instance_usage_audit          => $instance_usage_audit,
    instance_usage_audit_period   => $instance_usage_audit_period,
    reserved_host_memory          => $nova_hash_real['reserved_host_memory'],
    config_drive_format           => $config_drive_format,
    allow_resize_to_same_host     => true,
    vcpu_pin_set                  => $nova_hash_real['cpu_pinning'],
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
  class { '::nova::compute::libvirt':
    libvirt_virt_type                          => $libvirt_type,
    libvirt_cpu_mode                           => $libvirt_cpu_mode,
    libvirt_disk_cachemodes                    => $disk_cachemodes,
    libvirt_inject_partition                   => $libvirt_inject_partition,
    vncserver_listen                           => '0.0.0.0',
    remove_unused_original_minimum_age_seconds => pick($nova_hash_real['remove_unused_original_minimum_age_seconds'], '86400'),
    libvirt_service_name                       => $::nova::params::libvirt_service_name,
  }

  class { '::nova::migration::libvirt':
    override_uuid => true,
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
      ensure => 'running',
      enable => true,
      status => '/bin/true',
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
          path    => '/sbin:/usr/sbin:/bin:/usr/bin',
          unless  => 'lsmod | grep -q kvm',
          require => Package[$libvirt_type_kvm],
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

  include ::nova::client

  # Ensure ssh clients are installed
  case $::osfamily {
    'Debian': {
      $scp_package='openssh-client'
      $multipath_tools_package='multipath-tools'
    }
    'RedHat': {
      $scp_package='openssh-clients'
      $multipath_tools_package='device-mapper-multipath'
    }
    default: { fail("Unsupported osfamily: ${osfamily}") }
  }

  ensure_packages([$scp_package, $multipath_tools_package])

  $ssh_private_key   = '/var/lib/astute/nova/nova'
  $ssh_public_key    = '/var/lib/astute/nova/nova.pub'

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

  # TODO (iberezovskiy): remove this workaround in N when nova module
  # will be switched to puppet-oslo usage for rabbit configuration
  if $kombu_compression in ['gzip','bz2'] {
    if !defined(Oslo::Messaging_rabbit['nova_config']) and !defined(Nova_config['oslo_messaging_rabbit/kombu_compression']) {
      nova_config { 'oslo_messaging_rabbit/kombu_compression': value => $kombu_compression; }
    } else {
      Nova_config<| title == 'oslo_messaging_rabbit/kombu_compression' |> { value => $kombu_compression }
    }
  }

  # vim: set ts=2 sw=2 et :

}
