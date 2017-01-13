class osnailyfacter::database::database {

  notice('MODULAR: database/database.pp')

  $network_scheme = hiera_hash('network_scheme', {})
  prepare_network_config($network_scheme)

  $network_metadata  = hiera_hash('network_metadata', {})
  $use_syslog        = hiera('use_syslog', true)
  $mysql_hash        = hiera_hash('mysql', {})
  $debug             = pick($mysql_hash['debug'], hiera('debug', false))

  $mgmt_iface      = get_network_role_property('mgmt/database', 'interface')
  $direct_networks = split(direct_networks($network_scheme['endpoints'], $mgmt_iface, 'netmask'), ' ')
  # localhost is covered by mysql::server so we use this for detached db
  $access_networks = unique(flatten(['240.0.0.0/255.255.0.0', $direct_networks]))


  $primary_db                = has_primary_role(intersection(hiera('database_roles'), hiera('roles')))
  $mysql_root_password       = $mysql_hash['root_password']
  $deb_sysmaint_password     = $mysql_hash['wsrep_password']
  $enabled                   = pick($mysql_hash['enabled'], true)

  $galera_node_address       = get_network_role_property('mgmt/database', 'ipaddr')
  $galera_nodes              = values(get_node_to_ipaddr_map_by_network_role(hiera_hash('database_nodes'), 'mgmt/database'))
  $galera_cluster_name       = 'openstack'

  $mysql_skip_name_resolve  = true
  $custom_setup_class       = hiera('mysql_custom_setup_class', 'galera')

  $galera_gcache_size       = pick($mysql_hash['galera_gcache_size'], '512M')
  $mysql_binary_logs        = hiera('mysql_binary_logs', false)
  $log_bin                  = pick($mysql_hash['log_bin'], 'mysql-bin')
  $expire_logs_days         = pick($mysql_hash['expire_logs_days'], '1')
  $max_binlog_size          = pick($mysql_hash['max_binlog_size'], '256M')

  $status_user              = 'clustercheck'
  $status_password          = $mysql_hash['wsrep_password']
  $backend_port             = '3307'
  $backend_timeout          = '10'

  #############################################################################
  validate_string($status_password)
  validate_string($mysql_root_password)
  validate_string($status_password)

  if $enabled {

    if '/var/lib/mysql' in $::mounts {
      $ignore_db_dir_options = {
        'mysqld'          => {
          'ignore-db-dir' => ['lost+found'],
        }
      }
    } else {
      $ignore_db_dir_options = {}
    }

    case $custom_setup_class {
      'percona': {
        # percona provided by OS is the default from the galera module
        $vendor_type = 'percona'
        $mysql_package_name = undef
        $galera_package_name = undef
        $client_package_name = undef
        $mysql_socket = '/var/lib/mysql/mysql.sock'
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
            $mysql_socket = '/var/run/mysqld/mysqld.sock'
          }
          'RedHat': {
            $mysql_package_name = 'Percona-XtraDB-Cluster-server-56'
            $galera_package_name = 'Percona-XtraDB-Cluster-galera-4'
            $client_package_name = 'Percona-XtraDB-Cluster-client-56'
            $libgalera_prefix = '/usr/lib64/galera3'
            $mysql_socket = '/var/lib/mysql/mysql.sock'
            # This is a work around to prevent the conflict between the
            # MySQL-shared-wsrep package (included as a dependency for
            # MySQL-python) and the Percona shared package
            # Percona-XtraDB-Cluster-shared-56. They both
            # provide the libmysql client libraries. Since we are requiring the
            # installation of the Percona package here before mysql::python, the
            # python client is happy and the server installation won't fail due
            # to the installation of our shared package
            package { 'Percona-XtraDB-Cluster-shared-56':
              ensure => 'present',
              before => Class['::mysql::bindings'],
            }
          }
          default: { fail('unsupported os for percona_packages') }

        }
        $vendor_override_options = {
          'mysqld'           => {
            'wsrep_provider' => "${libgalera_prefix}/libgalera_smm.so"
          }
        }
      }
      default: {
        # MOS galera packages
        $vendor_type = 'MOS'
        $galera_package_name = 'galera-3'

        $mysql_package_name  = 'mysql-wsrep-server-5.6'
        $client_package_name = 'mysql-wsrep-client-5.6'

        case $::osfamily {
          'Debian': {
            $wsrep_provider = '/usr/lib/galera/libgalera_smm.so'
            $mysql_socket = '/var/run/mysqld/mysqld.sock'
          }
          'RedHat': {
            $wsrep_provider = '/usr/lib64/galera-3/libgalera_smm.so'
            $mysql_socket = '/var/lib/mysql/mysql.sock'
          }
        }

        $vendor_override_options = {
          'mysqld'           => {
            'wsrep_provider' => $wsrep_provider
          }
        }
      }
    }

    $wsrep_group_comm_port = '4567'
    if ($::memorysize_mb + 0) < 4000 {
      $mysql_performance_schema = 'off'
    } else {
      $mysql_performance_schema = 'on'
    }
    $innodb_buffer_pool_size = inline_template("<%= [(${::memorysize_mb} * 0.25).floor, 8192].min %>")
    $innodb_log_file_size    = inline_template("<%= [(${innodb_buffer_pool_size} * 0.2).floor, 2047].min %>")
    #http://dev.mysql.com/doc/refman/5.6/en/innodb-parameters.html#sysvar_innodb_log_buffer_size
    $innodb_log_buffer_size  = '8'
    #http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html#sysvar_key_buffer_size
    $key_buffer_size         = '8'
    #Disabled for galera
    $query_cache_size        = '0'
    #http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html#sysvar_tmp_table_size
    $tmp_table_size          = '16'
    #http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html#sysvar_read_buffer_size
    $read_buffer_size        = '0.125'
    #http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html#sysvar_read_rnd_buffer_size
    $read_rnd_buffer_size    = '0.25'
    #http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html#sysvar_sort_buffer_size
    $sort_buffer_size        = '0.25'
    #http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html#sysvar_join_buffer_size
    $join_buffer_size        = '0.25'
    #http://dev.mysql.com/doc/refman/5.6/en/replication-options-binary-log.html#sysvar_binlog_cache_size
    $binlog_cache_size       = '0.03125'
    #http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html#sysvar_thread_stack
    $thread_stack            = '0.25'

    $max_connections = inline_template("<%= [[((${::memorysize_mb} * 0.25 - ${key_buffer_size} - ${query_cache_size} - ${tmp_table_size} - ${innodb_log_buffer_size} ) /
         (${read_buffer_size} + ${read_rnd_buffer_size} + ${sort_buffer_size} + ${join_buffer_size} + ${binlog_cache_size} + ${thread_stack})).floor, 8192].min, 1024].max %>")

    $wsrep_provider_options = "\"gcache.size=${galera_gcache_size}; gmcast.listen_addr=tcp://${galera_node_address}:${wsrep_group_comm_port}\""
    $wsrep_slave_threads = inline_template("<%= [[${::processorcount}*2, 4].max, 12].min %>")

    if $use_syslog {
      $syslog_options = {
        'mysqld_safe'                    => {
          'syslog'                       => true,
          'log-error'                    => undef
        },
        'mysqld'                         => {
          'log-error'                    => undef
        },
      }
    }

    # this is configurable via hiera
    if $mysql_binary_logs {
      $binary_logs_options = {
        'mysqld'                         => {
          'log_bin'                      => $log_bin,
          'expire_logs_days'             => $expire_logs_days,
          'max_binlog_size'              => $max_binlog_size,
        },
      }
    }

    $fuel_override_options = {
      'mysqld'                           => {
        'port'                           => $backend_port,
        'max_connections'                => $max_connections,
        'pid-file'                       => undef,
        'log_bin'                        => undef,
        'expire_logs_days'               => undef,
        'max_binlog_size'                => undef,
        'collation-server'               => 'utf8_general_ci',
        'init-connect'                   => 'SET NAMES utf8',
        'character-set-server'           => 'utf8',
        'skip-name-resolve'              => $mysql_skip_name_resolve,
        'performance_schema'             => $mysql_performance_schema,
        'wait_timeout'                   => '1800',
        'open_files_limit'               => '102400',
        'table_open_cache'               => '10000',
        'key_buffer_size'                => "${key_buffer_size}M",
        'max_allowed_packet'             => '256M',
        'innodb-data-home-dir'           => '/var/lib/mysql',
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
      },
      'sst' => {
        'time' => $debug ? {true => '1', default => '0'}
      }
    }

    $server_list = join($galera_nodes, ',')
    $wsrep_options = {
      'mysqld'                           => {
        'binlog_format'                  => 'ROW',
        'default-storage-engine'         => 'innodb',
        'innodb_autoinc_lock_mode'       => '2',
        'innodb_locks_unsafe_for_binlog' => '1',
        'query_cache_size'               => '0',
        'query_cache_type'               => '0',
        'wsrep_cluster_address'          => "\"gcomm://${server_list}\"",
        'wsrep_cluster_name'             => $galera_cluster_name,
        'wsrep_provider_options'         => $wsrep_provider_options,
        'wsrep_slave_threads'            => $wsrep_slave_threads,
        'wsrep_sst_method'               => 'xtrabackup-v2',
        #TODO (sgolovatiuk): fix this, should be a specific user not root
        'wsrep_sst_auth'                 => "\"root:${mysql_root_password}\"",
        'wsrep_node_address'             => $galera_node_address,
        'wsrep_node_incoming_address'    => $galera_node_address,
        'wsrep_sst_receive_address'      => $galera_node_address,
      },
      'xtrabackup' => {
        'parallel' => inline_template(
                        "<%= [[${::processorcount}, 2].max, 6].min %>"
                      ),
      },
      'sst'        => {
        'streamfmt'   => 'xbstream',
        'transferfmt' => 'socat',
        'sockopts'    => 'nodelay,sndbuff=1048576,rcvbuf=1048576',
      }

    }

    tweaks::ubuntu_service_override { 'mysql':
      package_name => $mysql_package_name,
    }

    # build our mysql options to be configured in my.cnf
    $mysql_override_options = mysql_deepmerge(
      $fuel_override_options,
      $ignore_db_dir_options,
      $binary_logs_options,
      $syslog_options
    )
    $galera_options = mysql_deepmerge($wsrep_options, $vendor_override_options)
    $override_options = mysql_deepmerge($mysql_override_options, $galera_options)

    class { '::galera':
      vendor_type           => $vendor_type,
      mysql_package_name    => $mysql_package_name,
      galera_package_name   => $galera_package_name,
      client_package_name   => $client_package_name,
      galera_servers        => $galera_nodes,
      # NOTE: we don't want the galera module to boostrap
      galera_master         => false,
      mysql_port            => $backend_port,
      root_password         => $mysql_root_password,
      deb_sysmaint_password => $deb_sysmaint_password,
      create_root_user      => $primary_db,
      create_root_my_cnf    => $primary_db,
      configure_repo        => false, # NOTE: repos should be managed via fuel
      configure_firewall    => false,
      validate_connection   => false,
      status_check          => false,
      wsrep_group_comm_port => $wsrep_group_comm_port,
      bind_address          => $galera_node_address,
      local_ip              => $galera_node_address,
      wsrep_sst_method      => 'xtrabackup-v2',
      override_options      => $override_options,
    }

    # LP 1651182
    # Ensure that client library replacement is installed before we try
    # to install additional packages

    Class["mysql::client"] -> Package[$::galera::params::additional_packages]

    # Make sure the mysql service is stopped with upstart as we will be starting
    # it with pacemaker
    Exec <| title == 'clean_up_ubuntu' |> {
      command => 'service mysql stop || true'
    }

    $wsrep_config_file = '/etc/mysql/conf.d/wsrep.cnf'
    # Remove the wsrep config that comes from the packages as we put everything
    # in /etc/mysql/my.cnf
    file { $wsrep_config_file:
      ensure => absent,
      before => Class['::mysql::server::installdb'],
    }

    $management_networks = get_routable_networks_for_network_role($network_scheme, 'mgmt/database', ' ')
    # TODO(aschultz): switch to ::galera::status
    class { '::cluster::galera_status':
      status_user     => $status_user,
      status_password => $status_password,
      backend_host    => $galera_node_address,
      backend_port    => $backend_port,
      backend_timeout => $backend_timeout,
      only_from       => "127.0.0.1 240.0.0.2 ${management_networks}",
    }

    if $::osfamily == 'RedHat' {
      $mysql_config = '/etc/my.cnf'
    } else {
      $mysql_config = '/etc/mysql/my.cnf'
    }

    class { '::openstack::galera::client':
      custom_setup_class => $custom_setup_class,
    }

    # include our integration with pacemaker
    class { '::cluster::mysql':
      mysql_user     => $status_user,
      mysql_password => $status_password,
      mysql_config   => $mysql_config,
      mysql_socket   => $mysql_socket,
      require        => Class['::openstack::galera::client'],
    }

    # this overrides /root/.my.cnf created by mysql::server::root_password
    # TODO: (sgolovatiuk): This class should be removed once
    # https://github.com/puppetlabs/puppetlabs-mysql/pull/801/files is accepted
    class { '::osnailyfacter::mysql_access':
      db_password => $mysql_root_password,
      require     => Class['::galera'],
    }

    # this sets up remote grants for use with detached db
    if $primary_db {
      # We do not need to create users on all controllers as
      # whole /var/lib/mysql will be transferred during SST
      # Also this leads to split brain as MyISAM tables are got diverged
      class { '::osnailyfacter::mysql_user_access':
        db_user          => 'root',
        db_password_hash => mysql_password($mysql_root_password),
        access_networks  => $access_networks,
        require          => Class['::osnailyfacter::mysql_access'],
      }
      # We need to create user for galera cluster check
      class { '::cluster::galera_grants':
        status_user     => $status_user,
        status_password => $status_password,
        status_allow    => $galera_node_address,
      }
      if $::osfamily == 'Debian' {
        mysql_user { 'debian-sys-maint@localhost':
          ensure        => 'present',
          password_hash => mysql_password($deb_sysmaint_password),
          provider      => 'mysql',
          require       => File['/root/.my.cnf'],
        }
      }
      Class['::cluster::mysql'] ->
        Class['::cluster::galera_grants'] ->
          Class['::cluster::galera_status']
    }

    include ::osnailyfacter::database::database_backend_wait

    Class['::cluster::mysql'] ->
      Class['::cluster::galera_status'] ->
        ::Osnailyfacter::Wait_for_backend['mysql']
  }
}
