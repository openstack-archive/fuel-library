anchor { 'database-cluster-done':
  name => 'database-cluster-done',
}

anchor { 'database-cluster':
  before => ['Class[Mysql::Password]', 'Cs_resource[p_mysql]'],
  name   => 'database-cluster',
}

augeas { 'galeracheck':
  changes => ['set /files/etc/services/service-name[port = '49000']/port 49000', 'set /files/etc/services/service-name[port = '49000'] galeracheck', 'set /files/etc/services/service-name[port = '49000']/protocol tcp', 'set /files/etc/services/service-name[port = '49000']/#comment 'Galera Cluster Check''],
  context => '/files/etc/services',
  name    => 'galeracheck',
}

class { 'Galera::Params':
  name => 'Galera::Params',
}

class { 'Galera':
  before               => 'Class[Mysql::Server]',
  cluster_name         => 'openstack',
  gcache_factor        => '5',
  gcomm_port           => '4567',
  name                 => 'Galera',
  node_address         => '192.168.0.2',
  node_addresses       => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  primary_controller   => 'true',
  setup_multiple_gcomm => 'true',
  skip_name_resolve    => 'true',
  status_check         => 'true',
  use_percona          => 'false',
  use_percona_packages => 'false',
  use_syslog           => 'true',
  wsrep_sst_method     => 'xtrabackup-v2',
  wsrep_sst_password   => 'Lz18BpbQ',
}

class { 'Mysql::Config':
  bind_address       => '0.0.0.0',
  config_file        => '/etc/my.cnf',
  custom_setup_class => 'galera',
  datadir            => '/var/lib/mysql',
  debug              => 'false',
  default_engine     => 'UNSET',
  ignore_db_dirs     => [],
  log_error          => '/var/log/mysql/error.log',
  name               => 'Mysql::Config',
  pidfile            => '/var/run/mysqld/mysqld.pid',
  port               => '3306',
  root_group         => 'root',
  server_id          => '128',
  service_name       => 'mysql',
  socket             => '/var/run/mysqld/mysqld.sock',
  ssl                => 'false',
  ssl_ca             => '/etc/mysql/cacert.pem',
  ssl_cert           => '/etc/mysql/server-cert.pem',
  ssl_key            => '/etc/mysql/server-key.pem',
  use_syslog         => 'true',
  wait_timeout       => '3600',
}

class { 'Mysql::Params':
  name => 'Mysql::Params',
}

class { 'Mysql::Password':
  before            => 'Anchor[database-cluster-done]',
  config_file       => '/etc/my.cnf',
  etc_root_password => 'true',
  name              => 'Mysql::Password',
  old_root_password => '',
  root_password     => 'Lz18BpbQ',
}

class { 'Mysql::Server':
  before                  => 'Class[Osnailyfacter::Mysql_user]',
  bind_address            => '0.0.0.0',
  client_package_name     => 'mysql-client-5.5',
  config_hash             => {'config_file' => '/etc/my.cnf'},
  custom_setup_class      => 'galera',
  enabled                 => 'true',
  etc_root_password       => 'true',
  galera_cluster_name     => 'openstack',
  galera_gcache_factor    => '5',
  galera_node_address     => '192.168.0.2',
  galera_nodes            => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  ignore_db_dirs          => 'lost+found',
  initscript_file         => 'puppet:///modules/mysql/mysql-single.init',
  mysql_skip_name_resolve => 'true',
  name                    => 'Mysql::Server',
  old_root_password       => '',
  package_ensure          => 'present',
  package_name            => 'mysql-server-5.5',
  primary_controller      => 'true',
  rep_pass                => 'replicant666',
  rep_user                => 'replicator',
  replication_roles       => 'SELECT, PROCESS, FILE, SUPER, REPLICATION CLIENT, REPLICATION SLAVE, RELOAD',
  root_password           => 'Lz18BpbQ',
  server_id               => '128',
  service_name            => 'mysql',
  use_syslog              => 'true',
  wait_timeout            => '3600',
}

class { 'Openstack::Galera::Status':
  address         => '0.0.0.0',
  backend_host    => '192.168.0.2',
  backend_port    => '3307',
  backend_timeout => '10',
  before          => 'Haproxy_backend_status[mysql]',
  mysql_module    => '0.9',
  name            => 'Openstack::Galera::Status',
  only_from       => '127.0.0.1 240.0.0.2 192.168.0.0/24',
  port            => '49000',
  status_allow    => '192.168.0.2',
  status_password => 'JrlrVOHu',
  status_user     => 'clustercheck',
}

class { 'Osnailyfacter::Mysql_access':
  ensure      => 'present',
  db_host     => 'localhost',
  db_password => 'Lz18BpbQ',
  db_user     => 'root',
  name        => 'Osnailyfacter::Mysql_access',
}

class { 'Osnailyfacter::Mysql_user':
  access_networks => ['localhost', '127.0.0.1', '240.0.0.0/255.255.0.0', '192.168.0.0/255.255.255.0'],
  before          => 'Exec[initial_access_config]',
  name            => 'Osnailyfacter::Mysql_user',
  password        => 'Lz18BpbQ',
  user            => 'root',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Xinetd::Params':
  name => 'Xinetd::Params',
}

class { 'Xinetd':
  confdir            => '/etc/xinetd.d',
  conffile           => '/etc/xinetd.conf',
  name               => 'Xinetd',
  package_ensure     => 'installed',
  package_name       => 'xinetd',
  purge_confdir      => 'false',
  service_hasrestart => 'true',
  service_hasstatus  => 'false',
  service_name       => 'xinetd',
  service_restart    => '/usr/sbin/service xinetd reload',
}

class { 'main':
  name => 'main',
}

cs_resource { 'p_mysql':
  ensure          => 'present',
  before          => 'Service[mysql]',
  complex_type    => 'clone',
  name            => 'p_mysql',
  operations      => {'monitor' => {'interval' => '60', 'timeout' => '55'}, 'start' => {'timeout' => '300'}, 'stop' => {'timeout' => '120'}},
  parameters      => {'socket' => '/var/run/mysqld/mysqld.sock', 'test_passwd' => 'Lz18BpbQ', 'test_user' => 'wsrep_sst'},
  primitive_class => 'ocf',
  primitive_type  => 'mysql-wss',
  provided_by     => 'fuel',
}

database_grant { 'clustercheck@192.168.0.2/*.*':
  name       => 'clustercheck@192.168.0.2/*.*',
  privileges => 'Status_priv',
}

database_user { 'clustercheck@192.168.0.2':
  ensure        => 'present',
  before        => 'Database_grant[clustercheck@192.168.0.2/*.*]',
  name          => 'clustercheck@192.168.0.2',
  password_hash => '*5C6AF04DCED4381396375E96E49774A4664A0257',
  provider      => 'mysql',
  require       => 'Class[Mysql::Server]',
}

exec { 'initial_access_config':
  before  => 'Class[Openstack::Galera::Status]',
  command => '/bin/ln -sf /etc/mysql/conf.d/password.cnf /root/.my.cnf',
}

exec { 'mysql_drop_test':
  before  => ['Osnailyfacter::Mysql_grant[localhost]', 'Osnailyfacter::Mysql_grant[127.0.0.1]', 'Osnailyfacter::Mysql_grant[240.0.0.0/255.255.0.0]', 'Osnailyfacter::Mysql_grant[192.168.0.0/255.255.255.0]'],
  command => 'mysql -NBe "drop database if exists test"',
  creates => '/root/.my.cnf',
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

exec { 'mysql_flush_privileges':
  command => 'mysql -NBe "flush privileges"',
  creates => '/root/.my.cnf',
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

exec { 'mysql_root_127.0.0.1':
  command => 'mysql -NBe "grant all on *.* to 'root'@'127.0.0.1' with grant option"',
  creates => '/root/.my.cnf',
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

exec { 'mysql_root_192.168.0.0/255.255.255.0':
  command => 'mysql -NBe "grant all on *.* to 'root'@'192.168.0.0/255.255.255.0' with grant option"',
  creates => '/root/.my.cnf',
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

exec { 'mysql_root_240.0.0.0/255.255.0.0':
  command => 'mysql -NBe "grant all on *.* to 'root'@'240.0.0.0/255.255.0.0' with grant option"',
  creates => '/root/.my.cnf',
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

exec { 'mysql_root_localhost':
  command => 'mysql -NBe "grant all on *.* to 'root'@'localhost' with grant option"',
  creates => '/root/.my.cnf',
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

exec { 'mysql_root_password':
  before  => 'Exec[mysql_flush_privileges]',
  command => 'mysql -NBe "update mysql.user set password = password('Lz18BpbQ') where user = 'root'"',
  creates => '/root/.my.cnf',
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}

exec { 'remove_mysql_override':
  before  => 'Service[mysql]',
  command => 'rm -f /etc/init/mysql.override',
  onlyif  => 'test -f /etc/init/mysql.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'rm-init-file':
  command => '/bin/rm /tmp/wsrep-init-file',
  path    => '/usr/bin:/bin:/usr/sbin:/sbin',
}

exec { 'set_mysql_rootpw':
  before    => 'File[mysql_password]',
  command   => 'mysqladmin -u root  password Lz18BpbQ',
  logoutput => 'true',
  path      => '/usr/local/sbin:/usr/bin:/usr/local/bin',
  tries     => '10',
  try_sleep => '3',
  unless    => 'mysqladmin -u root -pLz18BpbQ status > /dev/null',
}

exec { 'wait-for-synced-state':
  before    => ['Exec[set_mysql_rootpw]', 'Exec[rm-init-file]'],
  command   => '/usr/bin/mysql -uwsrep_sst -pLz18BpbQ -Nbe "show status like 'wsrep_local_state_comment'" | /bin/grep -q Synced && sleep 10',
  path      => '/usr/bin:/bin:/usr/sbin:/sbin',
  tries     => '60',
  try_sleep => '5',
}

exec { 'wait-initial-sync':
  before      => ['Exec[set_mysql_rootpw]', 'Exec[wait-for-synced-state]'],
  command     => '/usr/bin/mysql -uwsrep_sst -pLz18BpbQ -Nbe "show status like 'wsrep_local_state_comment'" | /bin/grep -q -e Synced -e Initialized && sleep 10',
  path        => '/usr/bin:/bin:/usr/sbin:/sbin',
  refreshonly => 'true',
  tries       => '60',
  try_sleep   => '5',
}

file { '/etc/init.d/mysql':
  ensure  => 'present',
  mode    => '0644',
  path    => '/etc/init.d/mysql',
  require => 'Package[MySQL-server]',
}

file { '/etc/my.cnf':
  ensure  => 'present',
  before  => ['File[mysql_password]', 'File[mysql_password]'],
  content => '# #[mysqld]
# #datadir=/var/lib/mysql
# #socket=/var/lib/mysql/mysql.sock
# #user=mysql
# # Disabling symbolic-links is recommended to prevent assorted security risks
# #symbolic-links=0

[mysqld_safe]
syslog

# pid-file=/var/run/mysqld.pid

!includedir /etc/mysql/conf.d/
',
  path    => '/etc/my.cnf',
}

file { '/etc/mysql/conf.d/wsrep.cnf':
  ensure  => 'present',
  before  => 'Package[MySQL-server]',
  content => '[mysqld]
datadir=/var/lib/mysql
bind-address=192.168.0.2
port=3307
max_connections=8192
default-storage-engine=innodb
binlog_format=ROW
log_bin=mysql-bin
collation-server=utf8_general_ci
init-connect='SET NAMES utf8'
character-set-server=utf8
default-storage-engine=innodb
expire_logs_days=10

skip-external-locking
skip-name-resolve

myisam_sort_buffer_size=64M
wait_timeout=1800
open_files_limit=102400
table_open_cache=10000
key_buffer_size=64M
max_allowed_packet=256M
query_cache_size=0
query_cache_type=0

innodb_file_format=Barracuda
innodb_file_per_table=1
innodb_buffer_pool_size=6427M
innodb_log_file_size=1285M
innodb_read_io_threads=8
innodb_write_io_threads=8
innodb_io_capacity=500
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT
innodb_doublewrite=0
innodb_autoinc_lock_mode=2
innodb_locks_unsafe_for_binlog=1

wsrep_cluster_address="gcomm://192.168.0.2:4567,192.168.0.3:4567,192.168.0.4:4567?pc.wait_prim=no"
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name="openstack"

wsrep_slave_threads=8
wsrep_sst_method=xtrabackup-v2
wsrep_sst_auth=wsrep_sst:Lz18BpbQ
wsrep_node_address=192.168.0.2
wsrep_provider_options="gcache.size = 320M"
wsrep_provider_options="gmcast.listen_addr = tcp://192.168.0.2:4567"

[xtrabackup]
parallel=4

[sst]
streamfmt=xbstream
transferfmt=socat
sockopt=,nodelay,sndbuf=1048576,rcvbuf=1048576
',
  notify  => 'Service[mysql]',
  path    => '/etc/mysql/conf.d/wsrep.cnf',
  require => ['File[/etc/mysql/conf.d]', 'File[/etc/mysql]'],
}

file { '/etc/mysql/conf.d':
  ensure => 'directory',
  before => 'Package[MySQL-server]',
  path   => '/etc/mysql/conf.d',
}

file { '/etc/mysql/my.cnf':
  ensure  => 'absent',
  path    => '/etc/mysql/my.cnf',
  require => 'Class[Mysql::Server]',
}

file { '/etc/mysql':
  ensure => 'directory',
  before => 'Package[MySQL-server]',
  path   => '/etc/mysql',
}

file { '/etc/wsrepclustercheckrc':
  content => '
MYSQL_USERNAME="clustercheck"
MYSQL_PASSWORD="JrlrVOHu"
MYSQL_HOST="192.168.0.2"
MYSQL_PORT="3307"
AVAILABLE_WHEN_DONOR=${3:-1}
ERR_FILE="${4:-/dev/null}"
AVAILABLE_WHEN_READONLY=${5:-1}
DEFAULTS_EXTRA_FILE=${6:-/etc/my.cnf}

#Timeout exists for instances where mysqld may be hung
TIMEOUT=10
',
  mode    => '0755',
  path    => '/etc/wsrepclustercheckrc',
}

file { '/etc/xinetd.conf':
  ensure  => 'file',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT
#
# This is the master xinetd configuration file. Settings in the
# default section will be inherited by all service configurations
# unless explicitly overridden in the service configuration. See
# xinetd.conf in the man pages for a more detailed explanation of
# these attributes.

defaults
{
# The next two items are intended to be a quick access place to
# temporarily enable or disable services.
#
#       enabled         =
#       disabled        =

# Define general logging characteristics.
        log_type        = SYSLOG daemon info
        log_on_failure  = HOST
        log_on_success  = PID HOST DURATION EXIT

# Define access restriction defaults
#
#       no_access       =
#       only_from       =
#       max_load        = 0
        cps             = 50 10
        instances       = 50
        per_source      = 10

# Address and networking defaults
#
#       bind            =
#       mdns            = yes
        v6only          = no

# setup environmental attributes
#
#       passenv         =
        groups          = yes
        umask           = 002

# Generally, banners are not used. This sets up their global defaults
#
#       banner          =
#       banner_fail     =
#       banner_success  =
}

includedir /etc/xinetd.d
',
  group   => '0',
  mode    => '0644',
  notify  => 'Service[xinetd]',
  owner   => 'root',
  path    => '/etc/xinetd.conf',
  require => 'Package[xinetd]',
}

file { '/etc/xinetd.d/galeracheck':
  ensure  => 'present',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

service galeracheck
{
        port            = 49000
        disable         = no
        socket_type     = stream
        protocol        = tcp
        wait            = no
        user            = nobody
        group           = nogroup
        groups          = yes
        server          = /usr/bin/galeracheck
        bind            = 0.0.0.0
        only_from       = 127.0.0.1 240.0.0.2 192.168.0.0/24
        per_source      = UNLIMITED
        cps             = 512 10
        flags           = IPv4
}
',
  mode    => '0644',
  notify  => 'Service[xinetd]',
  owner   => 'root',
  path    => '/etc/xinetd.d/galeracheck',
  require => 'File[/etc/xinetd.d]',
}

file { '/etc/xinetd.d':
  ensure  => 'directory',
  group   => '0',
  mode    => '0755',
  notify  => 'Service[xinetd]',
  owner   => 'root',
  path    => '/etc/xinetd.d',
  purge   => 'false',
  recurse => 'false',
  require => 'Package[xinetd]',
}

file { '/tmp/wsrep-init-file':
  ensure  => 'present',
  before  => 'Service[mysql]',
  content => 'set wsrep_on='off';
delete from mysql.user where user='';
grant all on *.* to 'wsrep_sst'@'%' identified by 'Lz18BpbQ';
grant all on *.* to 'wsrep_sst'@'localhost' identified by 'Lz18BpbQ';
flush privileges;

',
  path    => '/tmp/wsrep-init-file',
}

file { 'create_mysql_override':
  ensure  => 'present',
  before  => ['Package[MySQL-server]', 'Exec[remove_mysql_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/mysql.override',
}

file { 'default-mysql-access-link':
  ensure => 'symlink',
  path   => '/root/.my.cnf',
  target => '/root/.my.localhost.cnf',
}

file { 'localhost-mysql-access':
  ensure  => 'present',
  content => '
[mysql]
user     = 'root'
password = 'Lz18BpbQ'
host     = 'localhost'

[client]
user     = 'root'
password = 'Lz18BpbQ'
host     = 'localhost'

[mysqldump]
user     = 'root'
password = 'Lz18BpbQ'
host     = 'localhost'

[mysqladmin]
user     = 'root'
password = 'Lz18BpbQ'
host     = 'localhost'

[mysqlcheck]
user     = 'root'
password = 'Lz18BpbQ'
host     = 'localhost'

',
  group   => 'root',
  mode    => '0640',
  owner   => 'root',
  path    => '/root/.my.localhost.cnf',
}

file { 'mysql_password':
  before  => 'Database_user[clustercheck@192.168.0.2]',
  content => '[client]
user=root
host=localhost
password=Lz18BpbQ
',
  group   => 'mysql',
  mode    => '0640',
  owner   => 'mysql',
  path    => '/etc/mysql/conf.d/password.cnf',
}

firewall { '101 xtrabackup':
  action => 'accept',
  before => 'Package[MySQL-server]',
  name   => '101 xtrabackup',
  port   => '4444',
  proto  => 'tcp',
}

haproxy_backend_status { 'mysql':
  before => 'Class[Osnailyfacter::Mysql_access]',
  name   => 'mysqld',
  url    => 'http://192.168.0.2:10000/;csv',
}

osnailyfacter::mysql_grant { '127.0.0.1':
  before  => 'Exec[mysql_root_password]',
  name    => '127.0.0.1',
  network => '127.0.0.1',
  user    => 'root',
}

osnailyfacter::mysql_grant { '192.168.0.0/255.255.255.0':
  before  => 'Exec[mysql_root_password]',
  name    => '192.168.0.0/255.255.255.0',
  network => '192.168.0.0/255.255.255.0',
  user    => 'root',
}

osnailyfacter::mysql_grant { '240.0.0.0/255.255.0.0':
  before  => 'Exec[mysql_root_password]',
  name    => '240.0.0.0/255.255.0.0',
  network => '240.0.0.0/255.255.0.0',
  user    => 'root',
}

osnailyfacter::mysql_grant { 'localhost':
  before  => 'Exec[mysql_root_password]',
  name    => 'localhost',
  network => 'localhost',
  user    => 'root',
}

package { 'MySQL-server':
  ensure => 'installed',
  before => 'Exec[remove_mysql_override]',
  name   => 'mysql-server-wsrep-5.6',
  notify => 'Exec[wait-initial-sync]',
}

package { 'galera':
  ensure => 'present',
  before => 'Package[MySQL-server]',
  name   => 'galera',
}

package { 'libaio1':
  ensure => 'present',
  before => ['Package[galera]', 'Package[MySQL-server]'],
  name   => 'libaio1',
}

package { 'mysql-client':
  ensure => 'present',
  before => 'Package[MySQL-server]',
  name   => 'mysql-client-5.6',
}

package { 'percona-xtrabackup':
  ensure => 'present',
  before => 'Package[MySQL-server]',
  name   => 'percona-xtrabackup',
}

package { 'perl':
  ensure => 'present',
  before => 'Package[MySQL-server]',
  name   => 'perl',
}

package { 'wget':
  ensure => 'present',
  before => 'Package[MySQL-server]',
  name   => 'wget',
}

package { 'xinetd':
  ensure => 'installed',
  before => 'Service[xinetd]',
  name   => 'xinetd',
}

service { 'mysql':
  ensure   => 'running',
  before   => ['Exec[set_mysql_rootpw]', 'Exec[wait-for-synced-state]', 'Anchor[database-cluster-done]', 'Exec[wait-initial-sync]'],
  enable   => 'true',
  name     => 'p_mysql',
  provider => 'pacemaker',
}

service { 'xinetd':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'false',
  name       => 'xinetd',
  require    => 'File[/etc/xinetd.conf]',
  restart    => '/usr/sbin/service xinetd reload',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'mysql':
  name         => 'mysql',
  package_name => 'MySQL-server',
  service_name => 'mysql',
}

xinetd::service { 'galeracheck':
  ensure                  => 'present',
  bind                    => '0.0.0.0',
  cps                     => '512 10',
  disable                 => 'no',
  flags                   => 'IPv4',
  group                   => 'nogroup',
  groups                  => 'yes',
  instances               => 'UNLIMITED',
  log_on_failure_operator => '+=',
  log_on_success_operator => '+=',
  name                    => 'galeracheck',
  only_from               => '127.0.0.1 240.0.0.2 192.168.0.0/24',
  per_source              => 'UNLIMITED',
  port                    => '49000',
  protocol                => 'tcp',
  require                 => 'Augeas[galeracheck]',
  server                  => '/usr/bin/galeracheck',
  service_name            => 'galeracheck',
  socket_type             => 'stream',
  user                    => 'nobody',
}

