class openstack_tasks::roles::compute {

  notice('MODULAR: roles/compute.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  $network_metadata = hiera_hash('network_metadata', {})
  $nova_report_interval = hiera('nova_report_interval', '60')
  $nova_service_down_time = hiera('nova_service_down_time', '180')
  prepare_network_config($network_scheme)

  # Pulling hiera
  $compute_hash                   = hiera_hash('compute', {})
  $public_vip                     = hiera('public_vip')
  $management_vip                 = hiera('management_vip')
  $mp_hash                        = hiera('mp')
  $debug                          = pick($compute_hash['debug'], hiera('debug', true))
  $storage_hash                   = hiera_hash('storage', {})
  $nova_hash                      = hiera_hash('nova', {})
  $nova_custom_hash               = hiera_hash('nova_custom', {})
  $rabbit_hash                    = hiera_hash('rabbit', {})
  $cinder_hash                    = hiera_hash('cinder', {})
  $ceilometer_hash                = hiera_hash('ceilometer', {})
  $access_hash                    = hiera_hash('access', {})
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
  $kombu_compression              = hiera('kombu_compression', $::os_service_default)
  $nova_cache                     = pick($nova_hash['use_cache'], true)
  $region_name                    = hiera('region', 'RegionOne')
  $keystone_tenant                = pick($nova_hash['tenant'], 'services')

  $internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', [$nova_hash['auth_protocol'], 'http'])
  $internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $admin_auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', [$nova_hash['auth_protocol'], 'http'])
  $admin_auth_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])

  $keystone_auth_uri = "${internal_auth_protocol}://${internal_auth_address}:5000/"
  $keystone_auth_url = "${admin_auth_protocol}://${admin_auth_address}:35357/"


  # get glance api servers list
  $glance_endpoint_default        = hiera('glance_endpoint', $management_vip)
  $glance_protocol                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
  $glance_endpoint                = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', $glance_endpoint_default)
  $glance_api_servers             = hiera('glance_api_servers', "${glance_protocol}://${glance_endpoint}:9292")

  $vncproxy_protocol                      = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'protocol', [$nova_hash['vncproxy_protocol'], 'http'])
  $vncproxy_host                          = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'hostname', [$public_vip])

  $block_device_allocate_retries          = hiera('block_device_allocate_retries', 300)
  $block_device_allocate_retries_interval = hiera('block_device_allocate_retries_interval', 3)

  #LP1670220 set libvirt service name to libvirtd for UCA
  $repo_setup              = hiera_hash('repo_setup', {})
  $repo_type               = pick_default($repo_setup['repo_type'], '')

  $transport_url = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')

  include ::osnailyfacter::test_compute

  $floating_hash = {}

  ##CALCULATED PARAMETERS

  $memcached_servers = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')

  # TODO(xarses): We need to validate this is needed
  if ($storage_hash['volumes_lvm']) {
    nova_config { 'keymgr/fixed_key':
      value => $cinder_hash[fixed_key];
    }
  }

  # Use Swift if it isn't replaced by Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) {
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
    'DEFAULT/use_cow_images'                         => { value => hiera('use_cow_images', 'True') },
    'libvirt/libvirt_inject_key'                     => { value => true },
    'libvirt/libvirt_inject_password'                => { value => true },
  }

  $nova_complete_hash = merge($nova_config_hash, $nova_custom_hash)

  class { '::nova::config':
    nova_config => $nova_complete_hash,
  }

  $rabbit_heartbeat_timeout_threshold = pick($nova_hash['rabbit_heartbeat_timeout_threshold'], $rabbit_hash['heartbeat_timeout_threshold'], 60)
  $rabbit_heartbeat_rate              = pick($nova_hash['rabbit_heartbeat_rate'], $rabbit_hash['rabbit_heartbeat_rate'], 2)

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
        ensure     => true,
        name       => 'libvirt-guests',
        enable     => false,
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
          mode    => '0775',
          require => Package[$libvirt_type_kvm],
        }
        exec { 'mount_hugetlbfs_1g':
          command => 'mount -t hugetlbfs hugetlbfs-kvm -o mode=775,gid=kvm,pagesize=1GB /mnt/hugepages_1GB',
          unless  => 'grep -q /mnt/hugepages_1GB /proc/mounts',
          path    => '/usr/sbin:/usr/bin:/sbin:/bin',
          require => File['/mnt/hugepages_1GB'],
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
    }
    # At this point $hugepages_1g_opts_ensure can be set to 'absent' or unset
    # Make sure that it's set to 'absent' and avoid errors
    if ! $hugepages_1g_opts_ensure {
      $hugepages_1g_opts_ensure = 'absent'
    }
    augeas { 'qemu_hugepages':
      context => '/files/etc/default/qemu-kvm',
      changes => $qemu_hugepages_value,
      notify  => Service['libvirt'],
    }
    if $repo_type != 'uca' {
     file_line { 'libvirt_hugetlbfs_mount':
      path    => '/etc/libvirt/qemu.conf',
      line    => $libvirt_hugetlbfs_mount,
      match   => '^hugetlbfs_mount =.*$',
      require => Package['libvirt'],
      notify  => Service['libvirt'],
    }


   }


      file_line { 'libvirt_1g_hugepages_apparmor':
      ensure  => $hugepages_1g_opts_ensure,
      path    => '/etc/apparmor.d/abstractions/libvirt-qemu',
      after   => 'owner "/run/hugepages/kvm/libvirt/qemu/',
      line    => '  owner "/mnt/hugepages_1GB/libvirt/qemu/**" rw,',
      require => Package['libvirt'],
      notify  => Exec['refresh_apparmor'],
    }
    file_line { '1g_hugepages_fstab':
      ensure => $hugepages_1g_opts_ensure,
      path   => '/etc/fstab',
      line   => 'hugetlbfs-kvm /mnt/hugepages_1GB hugetlbfs mode=775,gid=kvm,pagesize=1GB 0 0',
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

  class { '::nova':
    default_transport_url                  => $transport_url,
    glance_api_servers                     => $glance_api_servers,
    debug                                  => $debug,
    use_syslog                             => $use_syslog,
    use_stderr                             => $use_stderr,
    log_facility                           => $syslog_log_facility,
    state_path                             => $nova_hash_real['state_path'],
    report_interval                        => $nova_report_interval,
    service_down_time                      => $nova_service_down_time,
    notify_on_state_change                 => $notify_on_state_change,
    notification_driver                    => $ceilometer_hash['notification_driver'],
    cinder_catalog_info                    => pick($nova_hash_real['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
    kombu_compression                      => $kombu_compression,
    block_device_allocate_retries          => $block_device_allocate_retries,
    block_device_allocate_retries_interval => $block_device_allocate_retries_interval,
    rabbit_heartbeat_timeout_threshold     => $rabbit_heartbeat_timeout_threshold,
    rabbit_heartbeat_rate                  => $rabbit_heartbeat_rate,
    os_region_name                         => $region_name,
  }

  if $repo_type == 'uca' {
  class {'::nova::placement':
    password       => $nova_hash['user_password'],
    auth_url       => $keystone_auth_url,
    os_interface   => 'internal',
    project_name   => pick($nova_hash['admin_tenant_name'], $keystone_tenant),
    os_region_name => $region_name
    }
  }


  class { '::nova::cache':
    enabled          => $nova_cache,
    backend          => 'oslo_cache.memcache_pool',
    memcache_servers => $local_memcached_server,
  }

  class { '::nova::availability_zone':
    default_availability_zone => $nova_hash_real['default_availability_zone'],
    default_schedule_zone     => $nova_hash_real['default_schedule_zone'],
  }

  # CPU configuration created using host-model may not work as expected.
  # The guest CPU may differ from the configuration and it may also confuse
  # guest OS by using a combination of CPU features and other parameters (such
  # as CPUID level) that don't work. Until these issues are fixed, it's a good
  # idea to avoid using host-model
  # http://libvirt.org/formatdomain.html#elementsCPU
  # https://bugs.launchpad.net/mos/+bug/1618473
  $libvirt_cpu_mode = 'none'

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

  # Explicitly disable file injection by the means of nbd and libguestfs:
  # the former is known to have reliability problems, while the latter does not
  # work out of box on Ubuntu. Neither works with Ceph ephemerals. The solution
  # here is to use config drive + cloud-init instead. This allows us to unify
  # settings for Ubuntu vs CentOS, as well as Ceph vs file ephemerals.
  # See LP #1467860 , LP #1556819 and LP #1467579 for details.
  $libvirt_inject_partition = '-2'
  $force_config_drive = true

  # NOTE(bogdando) deploy compute node with disabled nova-compute
  #   service #LP1398817. The orchestration will start and enable it back
  #   after the deployment is done.
  # NOTE(bogdando) This maybe be changed, if the host aggregates implemented, bp disable-new-computes
  class { '::nova::compute':
    enabled                          => false,
    vncserver_proxyclient_address    => get_network_role_property('nova/api', 'ipaddr'),
    vncproxy_protocol                => $vncproxy_protocol,
    vncproxy_host                    => $vncproxy_host,
    vncproxy_port                    => $nova_hash_real['vncproxy_port'],
    force_config_drive               => $force_config_drive,
    pci_passthrough                  => nic_whitelist_to_json(get_nic_passthrough_whitelist('sriov')),
    instance_usage_audit             => $instance_usage_audit,
    instance_usage_audit_period      => $instance_usage_audit_period,
    reserved_host_memory             => $nova_hash_real['reserved_host_memory'],
    config_drive_format              => $config_drive_format,
    allow_resize_to_same_host        => true,
    vcpu_pin_set                     => $nova_hash_real['cpu_pinning'],
    resume_guests_state_on_host_boot => hiera('resume_guests_state_on_host_boot', 'False'),
  }

  nova_config {
    'libvirt/live_migration_flag':  value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST';
    'libvirt/block_migration_flag': value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_NON_SHARED_INC';
    'DEFAULT/connection_type':      value => 'libvirt';
  }

  # TODO (iberezovskiy): rework this option management once it's available in puppet-nova module
  if !defined(Nova_config['privsep_osbrick/helper_command']) {
    nova_config {
      'privsep_osbrick/helper_command': value => 'sudo nova-rootwrap /etc/nova/rootwrap.conf privsep-helper --config-file /etc/nova/nova.conf'
    }
  }

  if $use_syslog {
    nova_config {
      'DEFAULT/use_syslog_rfc_format':  value => true;
    }
  }

  if ($storage_hash['ephemeral_ceph'] or $storage_hash['volumes_ceph']) {
    $disk_cachemodes = ['"network=writeback,block=none"']
  } else {
    $disk_cachemodes = ['"file=directsync,block=none"']
  }

  # set image preallocation mode
  $preallocate_images = pick($nova_hash_real['preallocate_images'], 'space')
  validate_re($preallocate_images, '^(none|space)$')

 if $repo_type != 'uca' {
    $libvirt_service_name = 'libvirt-bin'
  }
  else {
    $libvirt_service_name = 'libvirtd'
  }

  # Configure libvirt for nova-compute
  class { '::nova::compute::libvirt':
    libvirt_virt_type                          => $libvirt_type,
    libvirt_cpu_mode                           => $libvirt_cpu_mode,
    libvirt_disk_cachemodes                    => $disk_cachemodes,
    libvirt_inject_partition                   => $libvirt_inject_partition,
    vncserver_listen                           => '0.0.0.0',
    remove_unused_original_minimum_age_seconds => pick($nova_hash_real['remove_unused_original_minimum_age_seconds'], '86400'),
    libvirt_service_name                       => $libvirt_service_name,
    virtlock_service_name                      => 'virtlockd',
    virtlog_service_name                       => 'virtlogd',
    preallocate_images                         => $preallocate_images,
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
    default: { fail("Unsupported osfamily: ${::osfamily}") }
  }

  Service<| title == 'libvirt'|> ~> Service<| title == 'nova-compute'|>
  Package<| title == "nova-compute-${libvirt_type}"|> ~>
  Service<| title == 'nova-compute'|>

  case $::osfamily {
    'RedHat': {
      if str2bool("${::selinux}") {
        file_line { 'qemu_selinux':
          path    => '/etc/libvirt/qemu.conf',
          line    => 'security_driver = "selinux"',
          require => Package['libvirt'],
          notify  => Service['libvirt']
        }
      } else {
        file_line { 'qemu_selinux_disabled':
          ensure            => absent,
          path              => '/etc/libvirt/qemu.conf',
          match             => '^security_driver',
          match_for_absence => true,
          require           => Package['libvirt'],
          notify            => Service['libvirt']
        }
      }
    }
    'Debian': {
      package { 'apparmor':
        ensure => installed,
      }

      service { 'apparmor':
        ensure  => running,
        require => Package['apparmor'],
      }

      file_line { 'qemu_apparmor':
        path    => '/etc/libvirt/qemu.conf',
        line    => 'security_driver = "apparmor"',
        require => [Package['libvirt'], Service['apparmor']],
        notify  => Service['libvirt']
      }

      file_line { 'apparmor_libvirtd':
        path    => '/etc/apparmor.d/usr.sbin.libvirtd',
        line    => "#  unix, # shouldn't be used for libvirt/qemu",
        match   => '^[#[:space:]]*unix',
        require => Package['libvirt'],
      }

      exec { 'refresh_apparmor':
        refreshonly => true,
        command     => '/sbin/apparmor_parser -r /etc/apparmor.d/usr.sbin.libvirtd',
        require     => Package['apparmor'],
        subscribe   => File_line['apparmor_libvirtd'],
      }
    }
    default: { fail("Unsupported osfamily: ${::osfamily}") }
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
    default: { fail("Unsupported osfamily: ${::osfamily}") }
  }

  ensure_packages([$scp_package, $multipath_tools_package])

}
