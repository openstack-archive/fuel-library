#
# === Class: openstack::db::mysql
#
# Create MySQL databases for all components of
# OpenStack that require a database
#
# === Parameters
#
# [mysql_root_password] Root password for mysql. Required.
# [keystone_db_password] Password for keystone database. Required.
# [glance_db_password] Password for glance database. Required.
# [nova_db_password] Password for nova database. Required.
# [mysql_bind_address] Address that mysql will bind to. Optional .Defaults to '0.0.0.0'.
# [mysql_account_security] If a secure mysql db should be setup. Optional .Defaults to true.
# [keystone_db_user] DB user for keystone. Optional. Defaults to 'keystone'.
# [keystone_db_dbname] DB name for keystone. Optional. Defaults to 'keystone'.
# [glance_db_user] DB user for glance. Optional. Defaults to 'glance'.
# [glance_db_dbname]. Name of glance DB. Optional. Defaults to 'glance'.
# [nova_db_user]. Name of nova DB user. Optional. Defaults to 'nova'.
# [nova_db_dbname]. Name of nova DB. Optional. Defaults to 'nova'.
# [allowed_hosts] List of hosts that are allowed access. Optional. Defaults to false.
# [enabled] If the db service should be started. Optional. Defaults to true.
#
# === Example
#
# class { 'openstack::db::mysql':
#    mysql_root_password  => 'changeme',
#    keystone_db_password => 'changeme',
#    glance_db_password   => 'changeme',
#    nova_db_password     => 'changeme',
#    allowed_hosts        => ['127.0.0.1', '10.0.0.%'],
#  }
class openstack::db::mysql (
    # Required MySQL
    # passwords
    $mysql_root_password,
    $keystone_db_password,
    $glance_db_password,
    $nova_db_password,
    $cinder_db_password,
    $neutron_db_password,
    $ceilometer_db_password,
    # MySQL
    $mysql_bind_address      = '0.0.0.0',
    $mysql_account_security  = true,
    # Keystone
    $keystone_db_user        = 'keystone',
    $keystone_db_dbname      = 'keystone',
    # Glance
    $glance_db_user          = 'glance',
    $glance_db_dbname        = 'glance',
    # Nova
    $nova_db_user            = 'nova',
    $nova_db_dbname          = 'nova',
    $allowed_hosts           = false,
    # Ceilometer
    $ceilometer              = false,
    $ceilometer_db_user      = 'ceilometer',
    $ceilometer_db_dbname    = 'ceilometer',
    # Cinder
    $cinder                  = true,
    $cinder_db_user          = 'cinder',
    $cinder_db_dbname        = 'cinder',
    # neutron
    $neutron                 = true,
    $neutron_db_user         = 'neutron',
    $neutron_db_dbname       = 'neutron',
    $enabled                 = true,
    $galera_cluster_name     = 'openstack',
    $primary_controller      = false,
    $galera_node_address     = '127.0.0.1',
    $db_host                = '127.0.0.1',
    $galera_nodes            = ['127.0.0.1'],
    $mysql_skip_name_resolve = false,
    $custom_setup_class      = undef,
    $use_syslog              = false,
) {

  if $custom_setup_class {
    file { '/etc/mysql/my.cnf':
      ensure    => absent,
      require   => Class['mysql::server']
    }
    $config_hash_real = {
      'config_file' => '/etc/my.cnf'
    }
  } else {
    $config_hash_real = {}
  }

  class { "mysql::server" :
    bind_address            => '0.0.0.0',
    etc_root_password       => true,
    root_password           => $mysql_root_password,
    old_root_password       => '',
    galera_cluster_name     => $galera_cluster_name,
    primary_controller      => $primary_controller,
    galera_node_address     => $galera_node_address,
    galera_nodes            => $galera_nodes,
    enabled                 => $enabled,
    custom_setup_class      => $custom_setup_class,
    mysql_skip_name_resolve => $mysql_skip_name_resolve,
    use_syslog              => $use_syslog,
    config_hash             => $config_hash_real,
  }

  # This removes default users and guest access
  if $mysql_account_security and $custom_setup_class == undef {
    class { 'mysql::server::account_security': }
  }

  if ($enabled) {
    # Create the Keystone db
    class { 'keystone::db::mysql':
      user          => $keystone_db_user,
      password      => $keystone_db_password,
      dbname        => $keystone_db_dbname,
      allowed_hosts => $allowed_hosts,
    }

    # Create the Glance db
    class { 'glance::db::mysql':
      user          => $glance_db_user,
      password      => $glance_db_password,
      dbname        => $glance_db_dbname,
      allowed_hosts => $allowed_hosts,
    }

    # Create the Nova db
    class { 'nova::db::mysql':
      user          => $nova_db_user,
      password      => $nova_db_password,
      dbname        => $nova_db_dbname,
      allowed_hosts => $allowed_hosts,
    }

    # Create the Ceilometer db
    if ($ceilometer) {
      class { 'ceilometer::db::mysql':
        user          => $ceilometer_db_user,
        password      => $ceilometer_db_password,
        dbname        => $ceilometer_db_dbname,
        allowed_hosts => $allowed_hosts,
      }
    }

    # create cinder db
    if ($cinder) {
      class { 'cinder::db::mysql':
        user          => $cinder_db_user,
        password      => $cinder_db_password,
        dbname        => $cinder_db_dbname,
        allowed_hosts => $allowed_hosts,
      }
    }

    # create neutron db
    if ($neutron) {
      class { 'neutron::db::mysql':
        user          => $neutron_db_user,
        password      => $neutron_db_password,
        dbname        => $neutron_db_dbname,
        allowed_hosts => $allowed_hosts,
        sync_db       => $primary_controller,
      }
    }
  }
}

