#
# == Class: openstack::all
#
# Class that performs a basic openstack all in one installation.
#
# === Parameters
#
#  [public_address] Public address used by vnchost. Required.
#  [public_interface] The interface used to route public traffic by the
#    network service.
#  [private_interface] The private interface used to bridge the VMs into a common network.
#  [floating_range] The floating ip range to be created. If it is false, then no floating ip range is created.
#    Optional. Defaults to false.
#  [fixed_range] The fixed private ip range to be created for the private VM network. Optional. Defaults to '10.0.0.0/24'.
#  [network_manager] The network manager to use for the nova network service.
#    Optional. Defaults to 'nova.network.manager.FlatDHCPManager'.
#  [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
#  [network_config] Used to specify network manager specific parameters .Optional. Defualts to {}.
#  [mysql_root_password] The root password to set for the mysql database. Optional. Defaults to sql_pass'.
#  [rabbit_password] The password to use for the rabbitmq user. Optional. Defaults to rabbit_pw'
#  [rabbit_user] The rabbitmq user to use for auth. Optional. Defaults to nova'.
#  [admin_email] The admin's email address. Optional. Defaults to someuser@some_fake_email_address.foo'.
#  [admin_password] The default password of the keystone admin. Optional. Defaults to ChangeMe'.
#  [keystone_db_password] The default password for the keystone db user. Optional. Defaults to keystone_pass'.
#  [keystone_admin_token] The default auth token for keystone. Optional. Defaults to keystone_admin_token'.
#  [nova_db_password] The nova db password. Optional. Defaults to nova_pass'.
#  [nova_user_password] The password of the keystone user for the nova service. Optional. Defaults to nova_pass'.
#  [glance_db_password] The password for the db user for glance. Optional. Defaults to 'glance_pass'.
#  [glance_user_password] The password of the glance service user. Optional. Defaults to 'glance_pass'.
#  [secret_key] The secret key for horizon. Optional. Defaults to 'dummy_secret_key'.
# [verbose] Rather to print more verbose (INFO+) output. If non verbose and non debug, would give syslog_log_level
#   (default is WARNING) output. Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option.
#   Optional. Defaults to false.
#  [purge_nova_config] Whether unmanaged nova.conf entries should be purged. Optional. Defaults to true.
#  [libvirt_type] The virualization type being controlled by libvirt.  Optional. Defaults to 'kvm'.
#  [nova_volume] The name of the volume group to use for nova volume allocation. Optional. Defaults to 'nova-volumes'.
#  [horizon] (bool) is horizon installed. Defaults to: true
#  [use_syslog] Rather or not service should log to syslog. Optional. Defaults to false.
#  [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
#  [syslog_log_level] logging level for non verbose and non debug mode. Optional.
#
# === Examples
#
#  class { 'openstack::all':
#    public_address       => '192.168.1.1',
#    mysql_root_password  => 'changeme',
#    rabbit_password      => 'changeme',
#    keystone_db_password => 'changeme',
#    keystone_admin_token => '12345',
#    admin_email          => 'my_email@mw.com',
#    admin_password       => 'my_admin_password',
#    nova_db_password     => 'changeme',
#    nova_user_password   => 'changeme',
#    glance_db_password   => 'changeme',
#    glance_user_password => 'changeme',
#    secret_key           => 'dummy_secret_key',
#  }
#
# === Authors
#
# Dan Bode <bodepd@gmail.com>
#
#
class openstack::all (
  # Required Network
  $public_address,
  $public_interface,
  $private_interface,
  $admin_email,
  # required password
  $mysql_root_password,
  $admin_password,
  $rabbit_password,
  $keystone_db_password,
  $keystone_admin_token,
  $glance_db_password,
  $glance_user_password,
  $nova_db_password,
  $nova_user_password,
  $secret_key,
  $internal_address = '127.0.0.1',
  $admin_address = '127.0.0.1',
  # cinder and quantum password are not required b/c they are
  # optional. Not sure what to do about this.
  $cinder_user_password    = 'cinder_pass',
  $cinder_db_password      = 'cinder_pass',
  $quantum_user_password   = 'quantum_pass',
  $quantum_db_password     = 'quantum_pass',
  # Database
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $allowed_hosts           = ['127.0.0.%'],
  # Keystone
  $keystone_db_user        = 'keystone',
  $keystone_db_dbname      = 'keystone',
  $keystone_admin_tenant   = 'admin',
  $region                  = 'RegionOne',
  # Glance Required
  $glance_db_user          = 'glance',
  $glance_db_dbname        = 'glance',
  # Nova
  $nova_db_user            = 'nova',
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = true,
  # Network
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $fixed_range             = '10.0.0.0/24',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $network_size            = 255,
  $auto_assign_floating_ip = false,
  $network_config          = {},
  $quantum                 = false,
  # Rabbit
  $rabbit_user             = 'nova',
  $rabbit_nodes            = ['127.0.0.1'],
  # Horizon
  $horizon                 = true,
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $swift                   = false,
  $horizon_app_links       = undef,
  # if the cinder management components should be installed
  $cinder                  = false,
  $cinder_db_user          = 'cinder',
  $cinder_db_dbname        = 'cinder',
  $cinder_iscsi_bind_addr  = false,
  $cinder_volume_group     = 'cinder-volumes',
  $nv_physical_volume      = undef,
  $manage_volumes          = false,
  $cinder_rate_limits      = undef,
  #
  $quantum_db_user         = 'quantum',
  $quantum_db_dbname       = 'quantum',
  # Virtaulization
  $libvirt_type            = 'kvm',
  # VNC
  $vnc_enabled             = true,
  # General
  $enabled                 = true,
  $verbose                 = false,
  $debug                   = false,
  $service_endpoint        = '127.0.0.1',
  $glance_backend          = 'file',
  $use_syslog              = false,
  $syslog_log_level        = 'WARNING',
  $syslog_log_facility_glance   = 'LOG_LOCAL2',
  $syslog_log_facility_cinder   = 'LOG_LOCAL3',
  $syslog_log_facility_neutron  = 'LOG_LOCAL4',
  $syslog_log_facility_nova     = 'LOG_LOCAL6',
  $syslog_log_facility_keystone = 'LOG_LOCAL7',
  $nova_rate_limits        = undef,
) {

  # Ensure things are run in order
  Class['openstack::db::mysql'] -> Class['openstack::keystone']
  Class['openstack::db::mysql'] -> Class['openstack::glance']

  if defined(Class['openstack::cinder']) {
        Class['openstack::db::mysql'] -> Class['openstack::cinder']
  }
 # set up mysql server
  if ($db_type == 'mysql') {
    if ($enabled) {
      Class['glance::db::mysql'] -> Class['glance::registry']
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@127.0.0.1/nova?charset=utf8"
    } else {
      $nova_db = false
    }
    class { 'openstack::db::mysql':
      mysql_root_password    => $mysql_root_password,
      mysql_account_security => $mysql_account_security,
      keystone_db_user       => $keystone_db_user,
      keystone_db_password   => $keystone_db_password,
      keystone_db_dbname     => $keystone_db_dbname,
      glance_db_user         => $glance_db_user,
      glance_db_password     => $glance_db_password,
      glance_db_dbname       => $glance_db_dbname,
      nova_db_user           => $nova_db_user,
      nova_db_password       => $nova_db_password,
      nova_db_dbname         => $nova_db_dbname,
      cinder                 => $cinder,
      cinder_db_user         => $cinder_db_user,
      cinder_db_password     => $cinder_db_password,
      cinder_db_dbname       => $cinder_db_dbname,
      quantum                => $quantum,
      quantum_db_user        => $quantum_db_user,
      quantum_db_password    => $quantum_db_password,
      quantum_db_dbname      => $quantum_db_dbname,
      allowed_hosts          => $allowed_hosts,
      enabled                => $enabled,
      use_syslog             => $use_syslog,
    }
  } else {
    fail("unsupported db type: ${db_type}")
  }

  ####### KEYSTONE ###########
  class { 'openstack::keystone':
    verbose                   => $verbose,
    debug                     => $debug,
    db_type                   => $db_type,
    db_host                   => '127.0.0.1',
    db_password               => $keystone_db_password,
    db_name                   => $keystone_db_dbname,
    db_user                   => $keystone_db_user,
    admin_token               => $keystone_admin_token,
    admin_tenant              => $keystone_admin_tenant,
    admin_email               => $admin_email,
    admin_password            => $admin_password,
    public_address            => $public_address,
    internal_address          => $internal_address,
    admin_address             => $admin_address,
    #region                    => $region,
    glance_user_password      => $glance_user_password,
    nova_user_password        => $nova_user_password,
    cinder                    => $cinder,
    cinder_user_password      => $cinder_user_password,
    quantum                   => $quantum,
    quantum_user_password     => $quantum_user_password,
    use_syslog                => $use_syslog,
    syslog_log_facility       => $syslog_log_facility_keystone,
    syslog_log_level          => $syslog_log_level,
  }

  ######## GLANCE ##########
  class { 'openstack::glance':
    verbose                   => $verbose,
    debug                     => $debug,
    db_type                   => $db_type,
    db_host                   => '127.0.0.1',
    bind_host                 => '0.0.0.0',
    glance_db_user            => $glance_db_user,
    glance_db_dbname          => $glance_db_dbname,
    glance_db_password        => $glance_db_password,
    glance_user_password      => $glance_user_password,
    auth_uri                  => "http://${service_endpoint}:5000/",
    keystone_host             => $service_endpoint,
    enabled                   => $enabled,
    glance_backend            => $glance_backend,
    registry_host             => $service_endpoint,
    use_syslog                => $use_syslog,
    syslog_log_facility       => $syslog_log_facility_glance,
    syslog_log_level          => $syslog_log_level,
  }

  ######## NOVA ###########

  # should be in the package dependencies
  package { 'python-amqp':
    ensure => present,
  }

  Package['python-amqp'] -> Class['nova']

  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  if ($cinder) {
    $enabled_apis = 'ec2,osapi_compute'
  }
  else {
    $enabled_apis = 'ec2,osapi_compute,osapi_volume'
  }

  ######### Cinder Controller Services ########
  if !defined(Class['openstack::cinder']) {
    class {'openstack::cinder':
      sql_connection       => "mysql://${cinder_db_user}:${cinder_db_password}@127.0.0.1/${cinder_db_dbname}?charset=utf8",
      rabbit_password      => $rabbit_password,
      cinder_user_password => $cinder_user_password,
      volume_group         => $cinder_volume_group,
      glance_api_servers   => "localhost:9292",
      physical_volume      => $nv_physical_volume,
      manage_volumes       => true,
      enabled              => true,
      iscsi_bind_host      => $cinder_iscsi_bind_addr,
      cinder_rate_limits   => $cinder_rate_limits,
      use_syslog           => $use_syslog,
      syslog_log_facility  => $syslog_log_facility_cinder,
      syslog_log_level     => $syslog_log_level,
      verbose              => $verbose,
      debug                => $debug,
    }
  } else {
    # Set up nova-volume
    class { 'lvm':
      loopfile => '/tmp/nova-volumes.lvm',
      vg       => 'nova-volumes',
      #pv       => '/dev/sdb',
      before   => Class['nova::volume'],
    }

    class { 'nova::volume':
      enabled => true,
      require => Class['lvm']
    }

    class { 'nova::volume::iscsi': }
  }

  # Install / configure rabbitmq
  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
    enabled  => $enabled,
  }

  # Configure Nova
  class { 'nova':
    sql_connection     => $nova_db,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "$internal_address:9292",
    verbose            => $verbose,
    use_syslog         => $use_syslog,
    syslog_log_facility => $syslog_log_facility_nova,
    syslog_log_level    => $syslog_log_level,
    debug              => $debug,
    rabbit_host        => '127.0.0.1',
  }

  # Configure nova-api
  class { 'nova::api':
    enabled           => $enabled,
    admin_password    => $nova_user_password,
    auth_host         => $service_endpoint,
    enabled_apis      => $enabled_apis,
    nova_rate_limits  => $nova_rate_limits,
    cinder            => $cinder,
  }

  # Configure nova-conductor
  class {'nova::conductor':
    enabled => $enabled,
    ensure_package  => $ensure_package,
  }

  # Configure nova-quota
  class { 'nova::quota': }

  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  if $quantum == false {
    # Configure nova-network
    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => $floating_range,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => $really_create_networks,
      num_networks      => $num_networks,
      network_size      => $network_size,
      enabled           => $enabled,
    }
  } else {
    # Set up Quantum
    $quantum_sql_connection = "mysql://${quantum_db_user}:${quantum_db_password}@127.0.0.1/${quantum_db_dbname}?charset=utf8"

    class { 'quantum':
      verbose         => $verbose,
      debug           => $debug,
      rabbit_host     => '127.0.0.1',
      rabbit_user     => $rabbit_user,
      rabbit_password => $rabbit_password,
      use_syslog      => $use_syslog,
      syslog_log_facility => $syslog_log_facility_neutron,
      syslog_log_level    => $syslog_log_level,
    }

    class { 'quantum::server':
      auth_password => $quantum_user_password,
    }

    class { 'quantum::agents::dhcp': }

    class { 'nova::compute::quantum': }

    nova_config {
      'DEFAULT/linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
      'DEFAULT/linuxnet_ovs_integration_bridge': value => 'br-int';
    }

    class { 'quantum::plugins::ovs':
      sql_connection      => $quantum_sql_connection,
      tenant_network_type => 'gre',
      enable_tunneling    => true,
    }

    class { 'quantum::agents::ovs':
      bridge_uplinks => ["br-virtual:${private_interface}"],
    }

    class { 'nova::network::quantum':
    #$fixed_range,
      quantum_admin_password    => $quantum_user_password,
    #$use_dhcp                  = 'True',
    #$public_interface          = undef,
      quantum_connection_host   => $service_endpoint,
      quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://$internal_address:9696",
      quantum_admin_tenant_name => 'services',
      #quantum_admin_username    => 'quantum',
      quantum_admin_auth_url    => "http://${admin_address}:35357/v2.0",
      public_interface          => $public_interface,
    }
  }

  if $auto_assign_floating_ip {
    nova_config { 'DEFAULT/auto_assign_floating_ip': value => 'True' }
  }

  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::cert',
    'nova::consoleauth'
  ]:
    enabled => $enabled,
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host          => $public_address,
      enabled       => $enabled,
    }
  }

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $public_address,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type            => $libvirt_type,
    vncserver_listen        => $internal_address,
    libvirt_disk_cachemodes => ['"file=directsync"','"block="none"'],
  }

  ######## Horizon ########
  if ($horizon) {
    class { 'memcached':
      listen_ip => '0.0.0.0',
    }

    class { 'openstack::horizon':
      secret_key        => $secret_key,
      cache_server_ip   => $cache_server_ip,
      cache_server_port => $cache_server_port,
      swift             => $swift,
      quantum           => $quantum,
      horizon_app_links => $horizon_app_links,
      bind_address      => $public_address,
      verbose           => $verbose,
      debug             => $debug,
      use_syslog        => $use_syslog,
      log_level         => $syslog_log_level,
    }
  }

}
