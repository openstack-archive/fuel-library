#
# == Class: openstack::keystone
#
# Installs and configures Keystone
#
# === Parameters
#
# [db_host] Host where DB resides. Required.
# [keystone_db_password] Password for keystone DB. Required.
# [keystone_admin_token]. Auth token for keystone admin. Required.
# [admin_email] Email address of system admin. Required.
# [admin_password]
# [glance_user_password] Auth password for glance user. Required.
# [nova_user_password] Auth password for nova user. Required.
# [public_address] Public address where keystone can be accessed. Required.
# [db_type] Type of DB used. Currently only supports mysql. Optional. Defaults to  'mysql'
# [keystone_db_user] Name of keystone db user. Optional. Defaults to  'keystone'
# [keystone_db_dbname] Name of keystone DB. Optional. Defaults to  'keystone'
# [keystone_admin_tenant] Name of keystone admin tenant. Optional. Defaults to  'admin'
# [verbose] Rather to print more verbose (INFO+) output. If non verbose and non debug, would
#    give syslog_log_level (default is WARNING) output. Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option.
#    Optional. Defaults to false.
# [bind_host] Address that keystone binds to. Optional. Defaults to  '0.0.0.0'
# [internal_address] Internal address for keystone. Optional. Defaults to  $public_address
# [admin_address] Keystone admin address. Optional. Defaults to  $internal_address
# [glance] Set up glance endpoints and auth. Optional. Defaults to  true
# [nova] Set up nova endpoints and auth. Optional. Defaults to  true
# [enabled] If the service is active (true) or passive (false).
#   Optional. Defaults to  true
# [use_syslog] Rather or not service should log to syslog. Optional. Default to false.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [syslog_log_level] logging level for non verbose and non debug mode. Optional.
#
# === Example
#
# class { 'openstack::keystone':
#   db_host               => '127.0.0.1',
#   keystone_db_password  => 'changeme',
#   keystone_admin_token  => '12345',
#   admin_email           => 'root@localhost',
#   admin_password        => 'changeme',
#   public_address        => '192.168.1.1',
#  }

class openstack::keystone (
  $db_host,
  $db_password,
  $admin_token,
  $admin_email,
  $admin_user = 'admin',
  $admin_password,
  $glance_user_password,
  $nova_user_password,
  $cinder_user_password,
  $ceilometer_user_password,
  $public_address,
  $db_type                  = 'mysql',
  $db_user                  = 'keystone',
  $db_name                  = 'keystone',
  $admin_tenant             = 'admin',
  $verbose                  = false,
  $debug                    = false,
  $bind_host                = '0.0.0.0',
  $internal_address         = false,
  $admin_address            = false,
  $glance_public_address    = false,
  $glance_internal_address  = false,
  $glance_admin_address     = false,
  $nova_public_address      = false,
  $nova_internal_address    = false,
  $nova_admin_address       = false,
  $cinder_public_address    = false,
  $cinder_internal_address  = false,
  $cinder_admin_address     = false,
  $quantum_config           = {},
  $quantum_public_address   = false,
  $quantum_internal_address = false,
  $quantum_admin_address    = false,
  $ceilometer_public_address   = false,
  $ceilometer_internal_address = false,
  $ceilometer_admin_address    = false,
  $glance                   = true,
  $nova                     = true,
  $cinder                   = true,
  $ceilometer               = true,
  $quantum                  = true,
  $enabled                  = true,
  $package_ensure           = present,
  $use_syslog               = false,
  $syslog_log_facility      = 'LOG_LOCAL7',
  $syslog_log_level = 'WARNING',
) {

  # Install and configure Keystone
  if $db_type == 'mysql' {
    $sql_conn = "mysql://${$db_user}:${db_password}@${db_host}/${db_name}?read_timeout=60"
  } else {
    fail("db_type ${db_type} is not supported")
  }

  # I have to do all of this crazy munging b/c parameters are not
  # set procedurally in Pupet
  if($internal_address) {
    $internal_real = $internal_address
  } else {
    $internal_real = $public_address
  }
  if($admin_address) {
    $admin_real = $admin_address
  } else {
    $admin_real = $internal_real
  }
  if($glance_public_address) {
    $glance_public_real = $glance_public_address
  } else {
    $glance_public_real = $public_address
  }
  if($glance_internal_address) {
    $glance_internal_real = $glance_internal_address
  } else {
    $glance_internal_real = $internal_real
  }
  if($glance_admin_address) {
    $glance_admin_real = $glance_admin_address
  } else {
    $glance_admin_real = $admin_real
  }
  if($nova_public_address) {
    $nova_public_real = $nova_public_address
  } else {
    $nova_public_real = $public_address
  }
  if($nova_internal_address) {
    $nova_internal_real = $nova_internal_address
  } else {
    $nova_internal_real = $internal_real
  }
  if($nova_admin_address) {
    $nova_admin_real = $nova_admin_address
  } else {
    $nova_admin_real = $admin_real
  }
  if($cinder_public_address) {
    $cinder_public_real = $cinder_public_address
  } else {
    $cinder_public_real = $public_address
  }
  if($cinder_internal_address) {
    $cinder_internal_real = $cinder_internal_address
  } else {
    $cinder_internal_real = $internal_real
  }
  if($cinder_admin_address) {
    $cinder_admin_real = $cinder_admin_address
  } else {
    $cinder_admin_real = $admin_real
  }
  if($quantum_public_address) {
    $quantum_public_real = $quantum_public_address
  } else {
    $quantum_public_real = $public_address
  }
  if($quantum_internal_address) {
    $quantum_internal_real = $quantum_internal_address
  } else {
    $quantum_internal_real = $internal_real
  }
  if($quantum_admin_address) {
    $quantum_admin_real = $quantum_admin_address
  } else {
    $quantum_admin_real = $admin_real
  }
  if($ceilometer_public_address) {
    $ceilometer_public_real = $ceilometer_public_address
  } else {
    $ceilometer_public_real = $public_address
  }
  if($ceilometer_internal_address) {
    $ceilometer_internal_real = $ceilometer_internal_address
  } else {
    $ceilometer_internal_real = $internal_real
  }
  if($ceilometer_admin_address) {
    $ceilometer_admin_real = $ceilometer_admin_address
  } else {
    $ceilometer_admin_real = $admin_real
  }

  class { '::keystone':
    verbose    => $verbose,
    debug      => $debug,
    catalog_type   => 'sql',
    admin_token    => $admin_token,
    enabled        => $enabled,
    sql_connection => $sql_conn,
    bind_host	=> $bind_host,
    package_ensure => $package_ensure,
    use_syslog => $use_syslog,
    syslog_log_facility => $syslog_log_facility,
    syslog_log_level    => $syslog_log_level,
  }

  if ($enabled) {
    # Setup the admin user
    class { 'keystone::roles::admin':
      admin        => $admin_user,
      email        => $admin_email,
      password     => $admin_password,
      admin_tenant => $admin_tenant,
    }

    # Setup the Keystone Identity Endpoint
    class { 'keystone::endpoint':
      public_address   => $public_address,
      admin_address    => $admin_real,
      internal_address => $internal_real,
    }

    # Configure Glance endpoint in Keystone
    if $glance {
      class { 'glance::keystone::auth':
        password         => $glance_user_password,
        public_address   => $glance_public_real,
        admin_address    => $glance_admin_real,
        internal_address => $glance_internal_real,
      }
    }

    # Configure Nova endpoint in Keystone
    if $nova {
      class { 'nova::keystone::auth':
        password         => $nova_user_password,
        public_address   => $nova_public_real,
        admin_address    => $nova_admin_real,
        internal_address => $nova_internal_real,
        cinder            => $cinder,
      }
    }

    # Configure Nova endpoint in Keystone
    if $cinder {
      class { 'cinder::keystone::auth':
        password         => $cinder_user_password,
        public_address   => $cinder_public_real,
        admin_address    => $cinder_admin_real,
        internal_address => $cinder_internal_real,
      }
    }
    if $quantum {
      class { 'neutron::keystone::auth':
        neutron_config   => $quantum_config,
        public_address   => $quantum_public_real,
        admin_address    => $quantum_admin_real,
        internal_address => $quantum_internal_real,
      }
    }
    if $ceilometer {
      class { 'ceilometer::keystone::auth':
        password         => $ceilometer_user_password,
        public_address   => $ceilometer_public_real,
        admin_address    => $ceilometer_admin_real,
        internal_address => $ceilometer_internal_real,
      }
    }
  }

}
