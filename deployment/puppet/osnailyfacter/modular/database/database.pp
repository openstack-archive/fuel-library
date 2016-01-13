notice('MODULAR: database.pp')

$network_scheme = hiera_hash('network_scheme', {})
prepare_network_config($network_scheme)
$use_syslog               = hiera('use_syslog', true)
$primary_controller       = hiera('primary_controller')
$mysql_hash               = hiera_hash('mysql', {})
$management_vip           = hiera('management_vip')
$database_vip             = hiera('database_vip', $management_vip)

$mgmt_iface = get_network_role_property('mgmt/database', 'interface')
$direct_networks = split(direct_networks($network_scheme['endpoints'], $mgmt_iface, 'netmask'), ' ')
$access_networks = flatten(['localhost', '127.0.0.1', '240.0.0.0/255.255.0.0', $direct_networks])

$haproxy_stats_port   = '10000'
$haproxy_stats_url    = "http://${database_vip}:${haproxy_stats_port}/;csv"

$mysql_database_password   = $mysql_hash['root_password']
$enabled                   = pick($mysql_hash['enabled'], true)

$galera_node_address       = get_network_role_property('mgmt/database', 'ipaddr')
$galera_nodes              = values(get_node_to_ipaddr_map_by_network_role(hiera_hash('database_nodes'), 'mgmt/database'))
#TODO(aschultz): make sure this can be overridden for detach-database
$galera_primary_controller = nodes_with_roles(hiera('nodes'), ['primary-controller'], 'fqdn')
#$galera_primary_controller = hiera('primary_database', $primary_controller)
$mysql_bind_address        = '0.0.0.0'
$galera_cluster_name       = 'openstack'

$mysql_skip_name_resolve  = true
$custom_setup_class       = hiera('mysql_custom_setup_class', 'galera')

# Get galera gcache factor based on cluster node's count
$galera_gcache_factor     = count(unique(filter_hash(hiera('nodes', []), 'uid')))

$status_user              = 'clustercheck'
$status_password          = $mysql_hash['wsrep_password']
$backend_port             = '3307'
$backend_timeout          = '10'

$external_lb = hiera('external_lb', false)

#############################################################################
validate_string($status_password)
validate_string($mysql_database_password)
validate_string($status_password)

if $enabled {

  #if $custom_setup_class {
  #  file { '/etc/mysql/my.cnf':
  #    ensure  => absent,
  #    require => Class['mysql::server']
  #  }
  #  $config_hash_real = {
  #    'config_file' => '/etc/my.cnf'
  #  }
  #} else {
  #  $config_hash_real = { }
  #}

  if '/var/lib/mysql' in split($::mounts, ',') {
    $ignore_db_dirs = ['lost+found']
  } else {
    $ignore_db_dirs = []
  }

  #class { 'mysql::server':
  #  bind_address            => '0.0.0.0',
  #  etc_root_password       => true,
  #  root_password           => $mysql_database_password,
  #  old_root_password       => '',
  #  galera_cluster_name     => $galera_cluster_name,
  #  primary_controller      => $galera_primary_controller,
  #  galera_node_address     => $galera_node_address,
  #  galera_nodes            => $galera_nodes,
  #  galera_gcache_factor    => $galera_gcache_factor,
  #  enabled                 => $enabled,
  #  custom_setup_class      => $custom_setup_class,
  #  mysql_skip_name_resolve => $mysql_skip_name_resolve,
  #  use_syslog              => $use_syslog,
  #  config_hash             => $config_hash_real,
  #  ignore_db_dirs          => $ignore_db_dirs,
  #}
  case $custom_setup_class {
    'percona': {
      # percona provided by OS is the default from the galera module
      $vendor_type = 'percona'
      $mysql_package_name = undef
      $galera_package_name = undef
      $client_package_name = undef
    }
    'percona_packages': {
      # percona provided by percona
      $vendor_type = 'percona'
      case $::osfamily {
        'Debian': {
          $mysql_package_name = 'percona-xtradb-cluster-server-5.6'
          $galera_package_name = 'percona-xtradb-cluster-galera-3.x'
          $client_package_name = 'percona-xtradb-cluster-client-5.6'
          $libgalera_prefix = '/usr/lib/galera3'
        }
        'RedHat': {
          $mysql_package_name = 'Percona-XtraDB-Cluster-server-56'
          $galera_package_name = 'Percona-XtraDB-Cluster-galera-4'
          $client_package_name = 'Percona-XtraDB-Cluster-client-56'
          $libgalera_prefix = '/usr/lib64/galera3'
        }
        default: { fail('unsupported os for percona_packages') }

      }
      $vendor_override_options = {
        'mysqld'           => {
          'wsrep_provider' => "${libgalera_prefix}/libgalera_ssm.so"
        }
      }
    }
    'mariadb': {
      $vendor_type = 'mariadb'
      $mysql_package_name = undef
      $galera_package_name = undef
      $client_package_name = undef
    }
    default: {
      # MOS galera packages
      $vendor_type = 'MOS'
      $mysql_package_name = 'mysql-server-wsrep-5.6'
      $galera_package_name = 'galera'
      $client_package_name = 'mysql-client-5.6'
      $vendor_override_options = {
        'mysqld'           => {
          'wsrep_provider' => '/usr/lib/galera/libgalera_smm.so'
        }
      }
    }
  }

  $gcache_size = inline_template("<%= [256, ${::galera_gcache_factor}*64, 2048].sort[1] %>M")
  $wsrep_group_comm_port = '4567'
  if $::memorysize_mb < 4000 {
    $mysql_performance_schema = 'off'
  } else {
    $mysql_performance_schema = 'on'
  }
  $innodb_buffer_pool_size = inline_template("<%= [(${::memorysize_mb} * 0.2 + 0).floor, 10000].min %>")
  $innodb_log_file_size = inline_template("<%= [(${innodb_buffer_pool_size} * 0.2 + 0).floor, 2047].min %>")
  $wsrep_provider_options = [
    "\"gcache.size = ${gcache_size}\"",
    "\"gmcast.listen_addr = tcp://${galera_node_address}:${wsrep_group_comm_port}\"",
  ]
  $wsrep_slave_threads = inline_template("<%= [[${::processorcount}*2, 4].max, 12].min %>")
  # TODO(aschultz): make binary log stuff configurable
  $fuel_override_options = {
    'mysqld'                           => {
      'port'                           => $backend_port,
      'max_connections'                => '', #TODO: check value
      'log_bin'                        => 'mysql-bin',
      'expire_logs_days'               => '1',
      'max_binlog_size'                => '512M',
      'collation-server'               => 'utf8_general_ci',
      'init-connect'                   => 'SET NAMES utf8',
      'ignore-db-dir'                  => join($ignore_db_dirs, ','),
      'character-set-server'           => 'utf8',
      'skip-name-resolve'              => $mysql_skip_name_resolve,
      'performance_schema'             => $mysql_performance_schema,
      'myisam_sort_buffer_size'        => '64M',
      'wait_timeout'                   => '1800',
      'open_files_limit'               => '102400',
      'table_open_cache'               => '10000',
      'key_buffer_size'                => '64',
      'max_allowed_packet'             => '256M',
      'query_cache_size'               => '0',
      'query_cache_type'               => '0',
      'innodb_file_format'             => 'Barracuda',
      'innodb_file_per_table'          => '1',
      'innodb_buffer_pool_size'        => "${innodb_buffer_pool_size}M",
      'innodb_log_file_size'           => "${innodb_log_file_size}M",
      'innodb_read_io_threads'         => '8',
      'innodb_write_io_threads'        => '8',
      'innodb_io_capacity'             => '500',
      'innodb_flush_log_at_trx_commit' => '2',
      'innodb_flush_method'            => 'O_DIRECT',
      'innodb_doublewrite'             => '0',
      'innodb_autoinc_lock_mode'       => '2',
      'innodb_locks_unsafe_for_binlog' => '1',
      # TODO: this is a hack to prevent the galera module from dropping these
      # in the default mysql config, fix the galera module to do the
      # bootstrapping correclty
      'wsrep_cluster_address'          => undef,
      'wsrep_cluster_name'             => undef,
      'wsrep_provider_options'         => undef,
      'wsrep_slave_threads'            => undef,
      'wsrep_sst_method'               => undef,
      'wsrep_sst_auth'                 => undef,
      'wsrep_node_address'             => undef,
      'wsrep_node_incoming_address'    => undef,
      'wsrep_sst_receive_address'      => undef,
      'wsrep_cluster_name'             => undef,
      'wsrep_provider'                 => undef,
      'wsrep_provider_options'         => undef,
      'wsrep_slave_threads'            => undef,
    },
  }

  $wsrep_options = {
    'mysqld'                           => {
      'binlog_format'                  => 'ROW',
      'default-storage-engine'         => 'innodb',
      'innodb_autoinc_lock_mode'       => '2',
      'innodb_locks_unsafe_for_binlog' => '1',
      'query_cache_size'               => '0',
      'query_cache_type'               => '0',
      'wsrep_cluster_address'          => 'gcomm://', #TODO deal with this after bootstrap
      'wsrep_cluster_name'             => $galera_cluster_name,
      'wsrep_provider_options'         => $wsrep_provider_options,
      'wsrep_slave_threads'            => $wsrep_slave_threads,
      'wsrep_sst_method'               => 'xtrabackup-v2',
      'wsrep_sst_auth'                 => "\"root:${mysql_database_password}\"", #TODO fix this, should be a specific user not root
      'wsrep_node_address'             => $galera_node_address,
      'wsrep_node_incoming_address'    => $galera_node_address,
      'wsrep_sst_receive_address'      => $galera_node_address,
    },
    'xtrabackup' => {
      'parallel' => inline_template("<%= [[${::processorcount}, 2].max, 6].min %>"),
    },
    'sst'        => {
      'streamfmt'   => 'xbstream',
      'transferfmt' => 'socat',
      'sockopts'    => ',nodelay,sndbuff=1048576,rcvbuf=1048576',
    }

  }
  tweaks::ubuntu_service_override { 'mysql':
    package_name => $mysql_package_name,
  }

  # TODO: moved the vendor options to the wsrep config file, not sure if that's right
  #$override_options = mysql_deepmerge($fuel_override_options, $vendor_override_options)

  class { '::galera':
    vendor_type           => $vendor_type,
    mysql_package_name    => $mysql_package_name,
    galera_package_name   => $galera_package_name,
    client_package_name   => $client_package_name,
    galera_servers        => $galera_nodes,
    galera_master         => $galera_primary_controller,
    mysql_port            => $backend_port,
    root_password         => $mysql_database_password,
    create_root_my_cnf    => true,
    validate_connection   => false,
    status_check          => false,
    wsrep_group_comm_port => $wsrep_group_comm_port,
    bind_address          => $mysql_bind_address,
    local_ip              => $galera_node_address,
    wsrep_sst_method      => 'xtrabackup-v2',
    override_options      => $fuel_override_options,
  }

  # TODO: update galera module to be able to skip this, we use tweaks for this
  Exec <| title == 'clean_up_ubuntu' |> {
    command => '/bin/true'
  }

  if ($custom_mysql_setup_class == 'percona_packages' and $::osfamily == 'RedHat') {
    # This is a work around to prevent the conflict between the
    # MySQL-shared-wsrep package (included as a dependency for MySQL-python) and
    # the Percona shared package Percona-XtraDB-Cluster-shared-56. They both
    # provide the libmysql client libraries. Since we are requiring the
    # installation of the Percona package here before mysql::python, the python
    # client is happy and the server installation won't fail due to the
    # installation of our shared package
    package { 'Percona-XtraDB-Cluster-shared-56':
      ensure => 'present',
      before => Class['mysql::bindings'],
    }
  }

  $management_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/database', ' ')

  #  class { 'osnailyfacter::mysql_user':
  #  password        => $mysql_database_password,
  #  access_networks => $access_networks,
  #}

  $wsrep_config_file = '/etc/mysql/conf.d/wsrep.cnf'

  # TODO: hack to build wsrep.cnf after mysql gets started, figure out if this is right
  $options = mysql_deepmerge($wsrep_options, $vendor_override_options)
  file { $wsrep_config_file:
    ensure                  => present,
    path                    => $wsrep_config_file,
    content                 => template('mysql/my.cnf.erb'),
    mode                    => '0644',
    selinux_ignore_defaults => true,
    require                 => Anchor['mysql::server::end'],
    notify                  => Exec['mysql-restart'], #TODO figure out a better way to do this as we want to configure wsrep after it's started once
  }

  exec { 'mysql-restart':
    path        => '/bin:/sbin:/usr/bin:/usr/sbin',
    command     => 'service mysql restart',
    refreshonly => true,
    require     => Service['mysql']
  }

  # TODO(aschultz): switch to ::galera::status
  class { 'openstack::galera::status':
    status_user     => $status_user,
    status_password => $status_password,
    status_allow    => $galera_node_address,
    backend_host    => $galera_node_address,
    backend_port    => $backend_port,
    backend_timeout => $backend_timeout,
    only_from       => "127.0.0.1 240.0.0.2 ${management_networks}",
  }

  if $external_lb {
    Haproxy_backend_status<||> {
      provider => 'http',
    }
  }

  haproxy_backend_status { 'mysql':
    name    => 'mysqld',
    url     => $external_lb ? {
      default => $haproxy_stats_url,
      # You should setup HTTP frontend for mysqld-status on yout external LB.
      # Otherwise it's impossible to wait for mysql cluster to sync.
      true    => "http://${database_vip}:49000",
    },
    require => [File[$wsrep_config_file], Service['mysqld']]
  }

  class { 'osnailyfacter::mysql_access':
    db_password => $mysql_database_password,
  }
}
