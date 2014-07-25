# Class: mysql::params
#
#   The mysql configuration settings.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::params {

  $bind_address        = '127.0.0.1'
  $port                = 3306
  $etc_root_password   = false
  $ssl                 = false
  $server_id           = delete(delete(delete("${::hostname}",'controller-'),'fuel-'),"node-")
  $service_provider = undef
  #TODO(bogdando) remove code duplication for galera and mysql manifests to openstack::db in 'I' release
  #Set buffer pool size to 30% of memory, but not greater than 10G
  $buffer_size             =
    inline_template("<%= [(${::memorysize_mb} * 0.3 + 0).floor, 10000].min %>")
  $mysql_buffer_pool_size  =  "${buffer_size}M"
  $mysql_log_file_size     =
    inline_template("<%= [(${buffer_size} * 0.25 + 0).floor, 2047].min %>M")
  $wait_timeout            = '3600'
  $myisam_sort_buffer_size = '64M'
  $key_buffer_size         = '64M'
  $table_open_cache        = '10000'
  $open_files_limit        = '102400'
  $max_connections         = '3000'

  case $::osfamily {
    'RedHat': {
      $basedir               = '/usr'
      $datadir               = '/var/lib/mysql'
      case $::operatingsystem {
        'RedHat': {
           $service_name          = 'mysqld'
           $client_package_name   = 'mysql'
           $client_version        = '5.1.69-1'
           $server_package_name   = 'mysql-server'
           $server_version        = '5.1.69-1'
           $shared_package_name   = 'mysql-libs'
           $shared_version        = '5.1.69-1'
         }
      default: {
           $service_name          = 'mysql'
           $client_package_name   = 'MySQL-client'
           $client_version        = '5.5.28_wsrep_23.7'
           $server_package_name   = 'MySQL-server'
           $server_version        = '5.5.28_wsrep_23.7'
           $shared_package_name   = 'MySQL-shared'
           $shared_version        = '5.5.28_wsrep_23.7'
         }
      }
      $socket                = '/var/lib/mysql/mysql.sock'
      $pidfile               = '/var/run/mysqld/mysqld.pid'
      $config_file           = '/etc/my.cnf'
      $log_error             = '/var/log/mysqld.log'
      $ruby_package_name     = 'ruby-mysql'
      $ruby_package_provider = 'gem'
      $python_package_name   = 'MySQL-python'
      $java_package_name     = 'mysql-connector-java'
      $root_group            = 'root'
      $ssl_ca                = '/etc/mysql/cacert.pem'
      $ssl_cert              = '/etc/mysql/server-cert.pem'
      $ssl_key               = '/etc/mysql/server-key.pem'
    }

    'Debian': {
      $basedir              = '/usr'
      $datadir              = '/var/lib/mysql'
      $service_name         = 'mysql'
      $client_package_name  = 'mysql-client-5.5'
      $server_package_name  = 'mysql-server-5.5'
      $shared_package_name  = 'mysql-common'
      $socket               = '/var/run/mysqld/mysqld.sock'
      $pidfile              = '/var/run/mysqld/mysqld.pid'
      $config_file          = '/etc/mysql/my.cnf'
      $log_error            = '/var/log/mysql/error.log'
      $ruby_package_name    = 'libmysql-ruby'
      $python_package_name  = 'python-mysqldb'
      $java_package_name    = 'libmysql-java'
      $root_group           = 'root'
      $ssl_ca               = '/etc/mysql/cacert.pem'
      $ssl_cert             = '/etc/mysql/server-cert.pem'
      $ssl_key              = '/etc/mysql/server-key.pem'
    }

    'FreeBSD': {
      $basedir               = '/usr/local'
      $datadir               = '/var/db/mysql'
      $service_name          = 'mysql-server'
      $client_package_name   = 'databases/mysql55-client'
      $client_version        = 'installed'
      $server_package_name   = 'databases/mysql55-server'
      $server_version        = 'installed'
      $shared_package_name   = 'databases/mysql55-server'
      $shared_version        = 'installed'
      $socket                = '/tmp/mysql.sock'
      $pidfile               = '/var/db/mysql/mysql.pid'
      $config_file           = '/var/db/mysql/my.cnf'
      $log_error             = "/var/db/mysql/${::hostname}.err"
      $ruby_package_name     = 'ruby-mysql'
      $ruby_package_provider = 'gem'
      $python_package_name   = 'databases/py-MySQLdb'
      $java_package_name     = 'databases/mysql-connector-java'
      $root_group            = 'wheel'
      $ssl_ca                = undef
      $ssl_cert              = undef
      $ssl_key               = undef
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat Debian and FreeBSD")
    }
  }

}
