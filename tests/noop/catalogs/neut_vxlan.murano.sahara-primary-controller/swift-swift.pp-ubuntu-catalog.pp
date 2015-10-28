anchor { 'swift-device-directories-start':
  before => ['Openstack::Swift::Storage_node::Device_directory[1]', 'Openstack::Swift::Storage_node::Device_directory[2]'],
  name   => 'swift-device-directories-start',
}

augeas { 'swiftcheck':
  changes => ['set /files/etc/services/service-name[port = '49001']/port 49001', 'set /files/etc/services/service-name[port = '49001'] swiftcheck', 'set /files/etc/services/service-name[port = '49001']/protocol tcp', 'set /files/etc/services/service-name[port = '49001']/#comment 'Swift Health Check''],
  context => '/files/etc/services',
  name    => 'swiftcheck',
}

class { 'Ceilometer':
  name => 'Ceilometer',
}

class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Keystone::Params':
  name => 'Keystone::Params',
}

class { 'Keystone::Python':
  ensure              => 'present',
  client_package_name => 'python-keystone',
  name                => 'Keystone::Python',
}

class { 'Memcached':
  before => 'Class[Swift::Proxy::Cache]',
  name   => 'Memcached',
}

class { 'Openstack::Swift::Proxy':
  admin_password                   => 'BP92J6tg',
  admin_tenant_name                => 'services',
  admin_user                       => 'swift',
  auth_host                        => '192.168.0.2',
  auth_protocol                    => 'http',
  before                           => 'Class[Openstack::Swift::Status]',
  ceilometer                       => 'false',
  collect_exported                 => 'false',
  debug                            => 'false',
  log_facility                     => 'LOG_SYSLOG',
  master_swift_proxy_ip            => '192.168.0.2',
  master_swift_replication_ip      => '192.168.1.2',
  name                             => 'Openstack::Swift::Proxy',
  package_ensure                   => 'present',
  primary_proxy                    => 'true',
  proxy_account_autocreate         => 'true',
  proxy_allow_account_management   => 'true',
  proxy_pipeline                   => ['catch_errors', 'crossdomain', 'healthcheck', 'cache', 'bulk', 'tempurl', 'ratelimit', 'formpost', 'swift3', 's3token', 'authtoken', 'keystone', 'staticweb', 'container_quotas', 'account_quotas', 'slo', 'proxy-server'],
  proxy_port                       => '8080',
  proxy_workers                    => '4',
  ratelimit_account_ratelimit      => '0',
  ratelimit_clock_accuracy         => '1000',
  ratelimit_log_sleep_time_seconds => '0',
  ratelimit_max_sleep_time_seconds => '60',
  ratelimit_rate_buffer_seconds    => '5',
  ring_min_part_hours              => '1',
  ring_part_power                  => '10',
  ring_replicas                    => '3',
  rings                            => ['account', 'object', 'container'],
  swift_hash_suffix                => 'swift_secret',
  swift_max_header_size            => '32768',
  swift_operator_roles             => ['admin', 'SwiftOperator'],
  swift_proxies_cache              => ['192.168.0.2', '192.168.0.3', '192.168.0.4'],
  swift_proxy_local_ipaddr         => '192.168.0.2',
  swift_replication_local_ipaddr   => '192.168.1.2',
  swift_user_password              => 'BP92J6tg',
  verbose                          => 'true',
}

class { 'Openstack::Swift::Status':
  address     => '0.0.0.0',
  before      => 'Class[Swift::Dispersion]',
  con_timeout => '5',
  endpoint    => 'http://192.168.0.2:8080',
  name        => 'Openstack::Swift::Status',
  only_from   => '127.0.0.1 240.0.0.2 192.168.1.0/24 192.168.0.0/24',
  port        => '49001',
  vip         => '192.168.0.2',
}

class { 'Openstack::Swift::Storage_node':
  before                      => 'Class[Swift::Dispersion]',
  cinder                      => 'true',
  cinder_db_dbname            => 'cinder',
  cinder_db_password          => 'cinder_db_pass',
  cinder_db_user              => 'cinder',
  cinder_iscsi_bind_addr      => 'false',
  cinder_rate_limits          => 'false',
  cinder_user_password        => 'cinder_user_pass',
  cinder_volume_group         => 'cinder-volumes',
  db_host                     => '127.0.0.1',
  debug                       => 'false',
  incoming_chmod              => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  log_facility                => 'LOG_SYSLOG',
  loopback_size               => '5243780',
  manage_volumes              => 'false',
  master_swift_proxy_ip       => '192.168.0.2',
  master_swift_replication_ip => '192.168.1.2',
  name                        => 'Openstack::Swift::Storage_node',
  outgoing_chmod              => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  package_ensure              => 'present',
  qpid_nodes                  => '127.0.0.1',
  qpid_password               => 'qpid_pw',
  qpid_user                   => 'nova',
  queue_provider              => 'rabbitmq',
  rabbit_ha_virtual_ip        => 'false',
  rabbit_host                 => 'false',
  rabbit_nodes                => 'false',
  rabbit_password             => 'rabbit_pw',
  rabbit_user                 => 'nova',
  rings                       => ['account', 'object', 'container'],
  service_endpoint            => '127.0.0.1',
  storage_base_dir            => '/srv/loopback-device',
  storage_devices             => ['1', '2'],
  storage_mnt_base_dir        => '/srv/node',
  storage_type                => 'false',
  storage_weight              => '1',
  swift_hash_suffix           => 'swift_secret',
  swift_local_net_ip          => '192.168.1.2',
  swift_max_header_size       => '32768',
  swift_zone                  => '1',
  sync_rings                  => 'false',
  syslog_log_facility_cinder  => 'LOG_LOCAL3',
  use_syslog                  => 'false',
  verbose                     => 'true',
}

class { 'Rsync::Server':
  address    => '192.168.1.2',
  gid        => 'nobody',
  motd_file  => 'UNSET',
  name       => 'Rsync::Server',
  uid        => 'nobody',
  use_chroot => 'no',
  use_xinetd => 'true',
}

class { 'Rsync':
  name           => 'Rsync',
  package_ensure => 'installed',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Swift::Client':
  ensure => 'present',
  name   => 'Swift::Client',
}

class { 'Swift::Dispersion':
  auth_pass     => 'BP92J6tg',
  auth_tenant   => 'services',
  auth_url      => 'http://192.168.0.2:5000/v2.0/',
  auth_user     => 'swift',
  auth_version  => '2.0',
  concurrency   => '25',
  coverage      => '1',
  dump_json     => 'no',
  endpoint_type => 'publicURL',
  name          => 'Swift::Dispersion',
  retries       => '5',
  swift_dir     => '/etc/swift',
}

class { 'Swift::Params':
  name => 'Swift::Params',
}

class { 'Swift::Proxy::Account_quotas':
  name => 'Swift::Proxy::Account_quotas',
}

class { 'Swift::Proxy::Authtoken':
  admin_password      => 'BP92J6tg',
  admin_tenant_name   => 'services',
  admin_token         => 'false',
  admin_user          => 'swift',
  auth_admin_prefix   => 'false',
  auth_host           => '192.168.0.2',
  auth_port           => '35357',
  auth_protocol       => 'http',
  auth_uri            => 'false',
  cache               => 'swift.cache',
  delay_auth_decision => '1',
  identity_uri        => 'false',
  name                => 'Swift::Proxy::Authtoken',
  signing_dir         => '/var/cache/swift',
}

class { 'Swift::Proxy::Bulk':
  max_containers_per_extraction => '10000',
  max_deletes_per_request       => '10000',
  max_failed_extractions        => '1000',
  name                          => 'Swift::Proxy::Bulk',
  yield_frequency               => '60',
}

class { 'Swift::Proxy::Cache':
  memcache_servers => ['192.168.0.2:11211', '192.168.0.3:11211', '192.168.0.4:11211'],
  name             => 'Swift::Proxy::Cache',
}

class { 'Swift::Proxy::Catch_errors':
  name => 'Swift::Proxy::Catch_errors',
}

class { 'Swift::Proxy::Container_quotas':
  name => 'Swift::Proxy::Container_quotas',
}

class { 'Swift::Proxy::Crossdomain':
  cross_domain_policy => '<allow-access-from domain="*" secure="false" />',
  name                => 'Swift::Proxy::Crossdomain',
}

class { 'Swift::Proxy::Formpost':
  name => 'Swift::Proxy::Formpost',
}

class { 'Swift::Proxy::Healthcheck':
  name => 'Swift::Proxy::Healthcheck',
}

class { 'Swift::Proxy::Keystone':
  is_admin        => 'true',
  name            => 'Swift::Proxy::Keystone',
  operator_roles  => ['admin', 'SwiftOperator'],
  reseller_prefix => 'AUTH_',
}

class { 'Swift::Proxy::Ratelimit':
  account_ratelimit      => '0',
  clock_accuracy         => '1000',
  log_sleep_time_seconds => '0',
  max_sleep_time_seconds => '60',
  name                   => 'Swift::Proxy::Ratelimit',
  rate_buffer_seconds    => '5',
}

class { 'Swift::Proxy::S3token':
  auth_host     => '192.168.0.2',
  auth_port     => '35357',
  auth_protocol => 'http',
  name          => 'Swift::Proxy::S3token',
}

class { 'Swift::Proxy::Slo':
  max_get_time                => '86400',
  max_manifest_segments       => '1000',
  max_manifest_size           => '2097152',
  min_segment_size            => '1048576',
  name                        => 'Swift::Proxy::Slo',
  rate_limit_after_segment    => '10',
  rate_limit_segments_per_sec => '0',
}

class { 'Swift::Proxy::Staticweb':
  name => 'Swift::Proxy::Staticweb',
}

class { 'Swift::Proxy::Swift3':
  ensure => 'present',
  name   => 'Swift::Proxy::Swift3',
}

class { 'Swift::Proxy::Tempurl':
  name => 'Swift::Proxy::Tempurl',
}

class { 'Swift::Proxy':
  account_autocreate       => 'true',
  allow_account_management => 'true',
  enabled                  => 'true',
  log_address              => '/dev/log',
  log_facility             => 'LOG_SYSLOG',
  log_handoffs             => 'true',
  log_headers              => 'False',
  log_level                => 'INFO',
  log_name                 => 'swift-proxy-server',
  manage_service           => 'true',
  name                     => 'Swift::Proxy',
  package_ensure           => 'present',
  pipeline                 => ['catch_errors', 'crossdomain', 'healthcheck', 'cache', 'bulk', 'tempurl', 'ratelimit', 'formpost', 'swift3', 's3token', 'authtoken', 'keystone', 'staticweb', 'container_quotas', 'account_quotas', 'slo', 'proxy-server'],
  port                     => '8080',
  proxy_local_net_ip       => '192.168.0.2',
  workers                  => '4',
}

class { 'Swift::Ringbuilder':
  before         => ['Class[Swift::Proxy]', 'Class[Swift::Ringserver]'],
  min_part_hours => '1',
  name           => 'Swift::Ringbuilder',
  part_power     => '10',
  replicas       => '3',
  require        => 'Class[Swift]',
}

class { 'Swift::Ringserver':
  local_net_ip    => '192.168.1.2',
  max_connections => '5',
  name            => 'Swift::Ringserver',
}

class { 'Swift::Storage::Account':
  enabled        => 'true',
  manage_service => 'true',
  name           => 'Swift::Storage::Account',
  package_ensure => 'present',
}

class { 'Swift::Storage::All':
  account_port         => '6002',
  allow_versions       => 'false',
  container_port       => '6001',
  devices              => '/srv/node',
  incoming_chmod       => '0644',
  log_facility         => 'LOG_SYSLOG',
  log_level            => 'INFO',
  log_requests         => 'true',
  name                 => 'Swift::Storage::All',
  object_port          => '6000',
  outgoing_chmod       => '0644',
  storage_local_net_ip => '192.168.1.2',
}

class { 'Swift::Storage::Container':
  allowed_sync_hosts => '127.0.0.1',
  enabled            => 'true',
  manage_service     => 'true',
  name               => 'Swift::Storage::Container',
  package_ensure     => 'present',
}

class { 'Swift::Storage::Object':
  enabled        => 'true',
  manage_service => 'true',
  name           => 'Swift::Storage::Object',
  package_ensure => 'present',
}

class { 'Swift::Storage':
  before               => ['Swift::Storage::Generic[account]', 'Swift::Storage::Generic[container]', 'Swift::Storage::Generic[object]'],
  name                 => 'Swift::Storage',
  storage_local_net_ip => '192.168.1.2',
}

class { 'Swift':
  before                => 'Class[Swift::Ringbuilder]',
  client_package_ensure => 'present',
  max_header_size       => '32768',
  name                  => 'Swift',
  package_ensure        => 'present',
  swift_hash_suffix     => 'swift_secret',
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

concat::fragment { 'frag-account':
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

[ account ]
path            = /srv/node
read only       = false
write only      = no
list            = yes
uid             = swift
gid             = swift
incoming chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
outgoing chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
max connections = 25
lock file       = /var/lock/account.lock
',
  name    => 'frag-account',
  order   => '10_account',
  target  => '/etc/rsyncd.conf',
}

concat::fragment { 'frag-container':
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

[ container ]
path            = /srv/node
read only       = false
write only      = no
list            = yes
uid             = swift
gid             = swift
incoming chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
outgoing chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
max connections = 25
lock file       = /var/lock/container.lock
',
  name    => 'frag-container',
  order   => '10_container',
  target  => '/etc/rsyncd.conf',
}

concat::fragment { 'frag-object':
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

[ object ]
path            = /srv/node
read only       = false
write only      = no
list            = yes
uid             = swift
gid             = swift
incoming chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
outgoing chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
max connections = 25
lock file       = /var/lock/object.lock
',
  name    => 'frag-object',
  order   => '10_object',
  target  => '/etc/rsyncd.conf',
}

concat::fragment { 'frag-swift_server':
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

[ swift_server ]
path            = /etc/swift
read only       = true
write only      = no
list            = yes
uid             = swift
gid             = swift
incoming chmod  = 0644
outgoing chmod  = 0644
max connections = 5
lock file       = /var/lock/swift_server.lock
',
  name    => 'frag-swift_server',
  order   => '10_swift_server',
  target  => '/etc/rsyncd.conf',
}

concat::fragment { 'rsyncd_conf_header':
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

pid file = /var/run/rsyncd.pid
uid = nobody
gid = nobody
use chroot = no
log format = %t %a %m %f %b
syslog facility = local3
timeout = 300
address = 192.168.1.2
',
  name    => 'rsyncd_conf_header',
  order   => '00_header',
  target  => '/etc/rsyncd.conf',
}

concat::fragment { 'swift-account-6002':
  before  => [],
  content => '[DEFAULT]
devices = /srv/node
bind_ip = 192.168.1.2
bind_port = 6002
mount_check = false
user = swift
workers = 1
log_name = swift-account-server
log_facility = LOG_SYSLOG
log_level = INFO
log_address = /dev/log



[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account
set log_name = swift-account-server
set log_facility = LOG_SYSLOG
set log_level = INFO
set log_requests = true
set log_address = /dev/log

[account-replicator]
concurrency = 4

[account-auditor]

[account-reaper]
concurrency = 4
',
  name    => 'swift-account-6002',
  order   => '00',
  require => 'Package[swift]',
  target  => '/etc/swift/account-server.conf',
}

concat::fragment { 'swift-container-6001':
  before  => [],
  content => '[DEFAULT]
devices = /srv/node
bind_ip = 192.168.1.2
bind_port = 6001
mount_check = false
user = swift
log_name = swift-container-server
log_facility = LOG_SYSLOG
log_level = INFO
log_address = /dev/log


workers = 1
allowed_sync_hosts = 127.0.0.1

[pipeline:main]
pipeline = container-server

[app:container-server]
allow_versions = true
use = egg:swift#container
set log_name = swift-container-server
set log_facility = LOG_SYSLOG
set log_level = INFO
set log_requests = true
set log_address = /dev/log

[container-replicator]
concurrency = 4

[container-updater]
concurrency = 4

[container-auditor]

[container-sync]
',
  name    => 'swift-container-6001',
  order   => '00',
  require => 'Package[swift]',
  target  => '/etc/swift/container-server.conf',
}

concat::fragment { 'swift-object-6000':
  before  => [],
  content => '[DEFAULT]
devices = /srv/node
bind_ip = 192.168.1.2
bind_port = 6000
mount_check = false
user = swift
log_name = swift-object-server
log_facility = LOG_SYSLOG
log_level = INFO
log_address = /dev/log


workers = 1

[pipeline:main]
pipeline = object-server

[app:object-server]
use = egg:swift#object
set log_name = swift-object-server
set log_facility = LOG_SYSLOG
set log_level = INFO
set log_requests = true
set log_address = /dev/log

[object-replicator]
concurrency = 4

[object-updater]
concurrency = 4

[object-auditor]
',
  name    => 'swift-object-6000',
  order   => '00',
  require => 'Package[swift]',
  target  => '/etc/swift/object-server.conf',
}

concat::fragment { 'swift-proxy-formpost':
  content => '
[filter:formpost]
use = egg:swift#formpost
',
  name    => 'swift-proxy-formpost',
  order   => '31',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift-proxy-staticweb':
  content => '
[filter:staticweb]
use = egg:swift#staticweb
',
  name    => 'swift-proxy-staticweb',
  order   => '32',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift-proxy-tempurl':
  content => '
[filter:tempurl]
use = egg:swift#tempurl
',
  name    => 'swift-proxy-tempurl',
  order   => '29',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_account_quotas':
  content => '
[filter:account_quotas]
use = egg:swift#account_quotas
',
  name    => 'swift_account_quotas',
  order   => '80',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_authtoken':
  content => '
[filter:authtoken]
log_name = swift
signing_dir = /var/cache/swift
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

auth_host = 192.168.0.2
auth_port = 35357
auth_protocol = http
auth_uri = http://192.168.0.2:5000
admin_tenant_name = services
admin_user = swift
admin_password = BP92J6tg
delay_auth_decision = 1
cache = swift.cache
include_service_catalog = False
',
  name    => 'swift_authtoken',
  order   => '22',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_bulk':
  content => '
[filter:bulk]
use = egg:swift#bulk
max_containers_per_extraction = 10000
max_failed_extractions = 1000
max_deletes_per_request = 10000
yield_frequency = 60
',
  name    => 'swift_bulk',
  order   => '21',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_cache':
  content => '
[filter:cache]
use = egg:swift#memcache
memcache_servers = 192.168.0.2:11211,192.168.0.3:11211,192.168.0.4:11211
',
  name    => 'swift_cache',
  order   => '23',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_catch_errors':
  content => '
[filter:catch_errors]
use = egg:swift#catch_errors
',
  name    => 'swift_catch_errors',
  order   => '24',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_container_quotas':
  content => '
[filter:container_quotas]
use = egg:swift#container_quotas
',
  name    => 'swift_container_quotas',
  order   => '81',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_crossdomain':
  content => '
[filter:crossdomain]
use = egg:swift#crossdomain
cross_domain_policy = <allow-access-from domain="*" secure="false" />
',
  name    => 'swift_crossdomain',
  order   => '35',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_healthcheck':
  content => '
[filter:healthcheck]
use = egg:swift#healthcheck
',
  name    => 'swift_healthcheck',
  order   => '25',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_keystone':
  content => '
[filter:keystone]
use = egg:swift#keystoneauth
operator_roles = admin, SwiftOperator
is_admin = true
reseller_prefix = AUTH_
',
  name    => 'swift_keystone',
  order   => '79',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_proxy':
  before  => ['Class[Swift::Proxy::Catch_errors]', 'Class[Swift::Proxy::Crossdomain]', 'Class[Swift::Proxy::Healthcheck]', 'Class[Swift::Proxy::Cache]', 'Class[Swift::Proxy::Bulk]', 'Class[Swift::Proxy::Tempurl]', 'Class[Swift::Proxy::Ratelimit]', 'Class[Swift::Proxy::Formpost]', 'Class[Swift::Proxy::Swift3]', 'Class[Swift::Proxy::S3token]', 'Class[Swift::Proxy::Authtoken]', 'Class[Swift::Proxy::Keystone]', 'Class[Swift::Proxy::Staticweb]', 'Class[Swift::Proxy::Container_quotas]', 'Class[Swift::Proxy::Account_quotas]', 'Class[Swift::Proxy::Slo]'],
  content => '# This file is managed by puppet.  Do not edit
#
[DEFAULT]
bind_port = 8080

bind_ip = 192.168.0.2

workers = 4
user = swift
log_name = swift-proxy-server
log_facility = LOG_SYSLOG
log_level = INFO
log_headers = False
log_address = /dev/log



[pipeline:main]
pipeline = catch_errors crossdomain healthcheck cache bulk tempurl ratelimit formpost swift3 s3token authtoken keystone staticweb container_quotas account_quotas slo proxy-server

[app:proxy-server]
use = egg:swift#proxy
set log_name = swift-proxy-server
set log_facility = LOG_SYSLOG
set log_level = INFO
set log_address = /dev/log
log_handoffs = true
allow_account_management = true
account_autocreate = true




',
  name    => 'swift_proxy',
  order   => '00',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_ratelimit':
  content => '
[filter:ratelimit]
use = egg:swift#ratelimit
clock_accuracy = 1000
max_sleep_time_seconds = 60
log_sleep_time_seconds = 0
rate_buffer_seconds = 5
account_ratelimit = 0
',
  name    => 'swift_ratelimit',
  order   => '26',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_s3token':
  content => '
[filter:s3token]
paste.filter_factory = keystonemiddleware.s3_token:filter_factory
auth_port = 35357
auth_protocol = http
auth_host = 192.168.0.2
',
  name    => 'swift_s3token',
  order   => '28',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_slo':
  content => '
[filter:slo]
use = egg:swift#slo
max_manifest_segments = 1000
max_manifest_size = 2097152
min_segment_size = 1048576
rate_limit_after_segment = 10
rate_limit_segments_per_sec = 0
max_get_time = 86400
',
  name    => 'swift_slo',
  order   => '35',
  target  => '/etc/swift/proxy-server.conf',
}

concat::fragment { 'swift_swift3':
  content => '
[filter:swift3]
use = egg:swift3#swift3
',
  name    => 'swift_swift3',
  order   => '27',
  target  => '/etc/swift/proxy-server.conf',
}

concat { '/etc/rsyncd.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  mode           => '0644',
  name           => '/etc/rsyncd.conf',
  order          => 'alpha',
  path           => '/etc/rsyncd.conf',
  replace        => 'true',
  warn           => 'false',
}

concat { '/etc/swift/account-server.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'swift',
  mode           => '0644',
  name           => '/etc/swift/account-server.conf',
  notify         => ['Service[swift-account]', 'Service[swift-account-replicator]'],
  order          => 'alpha',
  owner          => 'swift',
  path           => '/etc/swift/account-server.conf',
  replace        => 'true',
  require        => 'Package[swift]',
  warn           => 'false',
}

concat { '/etc/swift/container-server.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'swift',
  mode           => '0644',
  name           => '/etc/swift/container-server.conf',
  notify         => ['Service[swift-container]', 'Service[swift-container-replicator]'],
  order          => 'alpha',
  owner          => 'swift',
  path           => '/etc/swift/container-server.conf',
  replace        => 'true',
  require        => 'Package[swift]',
  warn           => 'false',
}

concat { '/etc/swift/object-server.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'swift',
  mode           => '0644',
  name           => '/etc/swift/object-server.conf',
  notify         => ['Service[swift-object]', 'Service[swift-object-replicator]'],
  order          => 'alpha',
  owner          => 'swift',
  path           => '/etc/swift/object-server.conf',
  replace        => 'true',
  require        => 'Package[swift]',
  warn           => 'false',
}

concat { '/etc/swift/proxy-server.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'swift',
  mode           => '0644',
  name           => '/etc/swift/proxy-server.conf',
  order          => 'alpha',
  owner          => 'swift',
  path           => '/etc/swift/proxy-server.conf',
  replace        => 'true',
  require        => 'Package[swift-proxy]',
  warn           => 'false',
}

exec { 'concat_/etc/rsyncd.conf':
  alias     => 'concat_/tmp//_etc_rsyncd.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_rsyncd.conf/fragments.concat.out" -d "/tmp//_etc_rsyncd.conf"',
  notify    => 'File[/etc/rsyncd.conf]',
  require   => ['File[/tmp//_etc_rsyncd.conf]', 'File[/tmp//_etc_rsyncd.conf/fragments]', 'File[/tmp//_etc_rsyncd.conf/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_rsyncd.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_rsyncd.conf/fragments.concat.out" -d "/tmp//_etc_rsyncd.conf" -t',
}

exec { 'concat_/etc/swift/account-server.conf':
  alias     => 'concat_/tmp//_etc_swift_account-server.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_swift_account-server.conf/fragments.concat.out" -d "/tmp//_etc_swift_account-server.conf"',
  notify    => 'File[/etc/swift/account-server.conf]',
  require   => ['File[/tmp//_etc_swift_account-server.conf]', 'File[/tmp//_etc_swift_account-server.conf/fragments]', 'File[/tmp//_etc_swift_account-server.conf/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_swift_account-server.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_swift_account-server.conf/fragments.concat.out" -d "/tmp//_etc_swift_account-server.conf" -t',
}

exec { 'concat_/etc/swift/container-server.conf':
  alias     => 'concat_/tmp//_etc_swift_container-server.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_swift_container-server.conf/fragments.concat.out" -d "/tmp//_etc_swift_container-server.conf"',
  notify    => 'File[/etc/swift/container-server.conf]',
  require   => ['File[/tmp//_etc_swift_container-server.conf]', 'File[/tmp//_etc_swift_container-server.conf/fragments]', 'File[/tmp//_etc_swift_container-server.conf/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_swift_container-server.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_swift_container-server.conf/fragments.concat.out" -d "/tmp//_etc_swift_container-server.conf" -t',
}

exec { 'concat_/etc/swift/object-server.conf':
  alias     => 'concat_/tmp//_etc_swift_object-server.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_swift_object-server.conf/fragments.concat.out" -d "/tmp//_etc_swift_object-server.conf"',
  notify    => 'File[/etc/swift/object-server.conf]',
  require   => ['File[/tmp//_etc_swift_object-server.conf]', 'File[/tmp//_etc_swift_object-server.conf/fragments]', 'File[/tmp//_etc_swift_object-server.conf/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_swift_object-server.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_swift_object-server.conf/fragments.concat.out" -d "/tmp//_etc_swift_object-server.conf" -t',
}

exec { 'concat_/etc/swift/proxy-server.conf':
  alias     => 'concat_/tmp//_etc_swift_proxy-server.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_swift_proxy-server.conf/fragments.concat.out" -d "/tmp//_etc_swift_proxy-server.conf"',
  notify    => 'File[/etc/swift/proxy-server.conf]',
  require   => ['File[/tmp//_etc_swift_proxy-server.conf]', 'File[/tmp//_etc_swift_proxy-server.conf/fragments]', 'File[/tmp//_etc_swift_proxy-server.conf/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_swift_proxy-server.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_swift_proxy-server.conf/fragments.concat.out" -d "/tmp//_etc_swift_proxy-server.conf" -t',
}

exec { 'create_account':
  command => 'swift-ring-builder /etc/swift/account.builder create 10 3 1',
  creates => '/etc/swift/account.builder',
  path    => '/usr/bin',
  user    => 'swift',
}

exec { 'create_container':
  command => 'swift-ring-builder /etc/swift/container.builder create 10 3 1',
  creates => '/etc/swift/container.builder',
  path    => '/usr/bin',
  user    => 'swift',
}

exec { 'create_object':
  command => 'swift-ring-builder /etc/swift/object.builder create 10 3 1',
  creates => '/etc/swift/object.builder',
  path    => '/usr/bin',
  user    => 'swift',
}

exec { 'rebalance_account':
  command     => 'swift-ring-builder /etc/swift/account.builder rebalance',
  path        => '/usr/bin',
  refreshonly => 'true',
  returns     => ['0', '1'],
  user        => 'swift',
}

exec { 'rebalance_container':
  command     => 'swift-ring-builder /etc/swift/container.builder rebalance',
  path        => '/usr/bin',
  refreshonly => 'true',
  returns     => ['0', '1'],
  user        => 'swift',
}

exec { 'rebalance_object':
  command     => 'swift-ring-builder /etc/swift/object.builder rebalance',
  path        => '/usr/bin',
  refreshonly => 'true',
  returns     => ['0', '1'],
  user        => 'swift',
}

exec { 'swift-dispersion-populate':
  command   => 'swift-dispersion-populate',
  onlyif    => 'swift -A http://192.168.0.2:5000/v2.0/ -U services:swift -K BP92J6tg -V 2.0 stat | grep 'Account: '',
  path      => ['/bin', '/usr/bin'],
  require   => 'Package[swiftclient]',
  subscribe => 'File[/etc/swift/dispersion.conf]',
  timeout   => '0',
  unless    => 'swift -A http://192.168.0.2:5000/v2.0/ -U services:swift -K BP92J6tg -V 2.0 list | grep dispersion_',
}

file { '/etc/init/swift-container-sync.conf':
  path    => '/etc/init/swift-container-sync.conf',
  require => 'Package[swift-container]',
  source  => 'puppet:///modules/swift/swift-container-sync.conf.upstart',
}

file { '/etc/rsyncd.conf':
  ensure  => 'present',
  alias   => 'concat_/etc/rsyncd.conf',
  backup  => 'puppet',
  mode    => '0644',
  path    => '/etc/rsyncd.conf',
  replace => 'true',
  source  => '/tmp//_etc_rsyncd.conf/fragments.concat.out',
}

file { '/etc/swift/account-server.conf':
  ensure  => 'present',
  alias   => 'concat_/etc/swift/account-server.conf',
  backup  => 'puppet',
  group   => 'swift',
  mode    => '0644',
  owner   => 'swift',
  path    => '/etc/swift/account-server.conf',
  replace => 'true',
  source  => '/tmp//_etc_swift_account-server.conf/fragments.concat.out',
}

file { '/etc/swift/account-server/':
  ensure => 'directory',
  path   => '/etc/swift/account-server',
}

file { '/etc/swift/backups':
  ensure  => 'directory',
  before  => 'Class[Swift::Proxy]',
  group   => 'swift',
  mode    => '2770',
  owner   => 'swift',
  path    => '/etc/swift/backups',
  require => 'Package[swift]',
}

file { '/etc/swift/container-server.conf':
  ensure  => 'present',
  alias   => 'concat_/etc/swift/container-server.conf',
  backup  => 'puppet',
  group   => 'swift',
  mode    => '0644',
  owner   => 'swift',
  path    => '/etc/swift/container-server.conf',
  replace => 'true',
  source  => '/tmp//_etc_swift_container-server.conf/fragments.concat.out',
}

file { '/etc/swift/container-server/':
  ensure => 'directory',
  path   => '/etc/swift/container-server',
}

file { '/etc/swift/dispersion.conf':
  ensure  => 'file',
  group   => 'swift',
  owner   => 'swift',
  path    => '/etc/swift/dispersion.conf',
  require => 'Package[swift]',
}

file { '/etc/swift/object-server.conf':
  ensure  => 'present',
  alias   => 'concat_/etc/swift/object-server.conf',
  backup  => 'puppet',
  group   => 'swift',
  mode    => '0644',
  owner   => 'swift',
  path    => '/etc/swift/object-server.conf',
  replace => 'true',
  source  => '/tmp//_etc_swift_object-server.conf/fragments.concat.out',
}

file { '/etc/swift/object-server/':
  ensure => 'directory',
  path   => '/etc/swift/object-server',
}

file { '/etc/swift/proxy-server.conf':
  ensure  => 'present',
  alias   => 'concat_/etc/swift/proxy-server.conf',
  backup  => 'puppet',
  group   => 'swift',
  mode    => '0644',
  owner   => 'swift',
  path    => '/etc/swift/proxy-server.conf',
  replace => 'true',
  source  => '/tmp//_etc_swift_proxy-server.conf/fragments.concat.out',
}

file { '/etc/swift/swift.conf':
  ensure  => 'file',
  before  => ['Swift_config[swift-hash/swift_hash_path_suffix]', 'Swift_config[swift-constraints/max_header_size]'],
  group   => 'swift',
  owner   => 'swift',
  path    => '/etc/swift/swift.conf',
  require => 'Package[swift]',
}

file { '/etc/swift':
  ensure  => 'directory',
  group   => 'swift',
  owner   => 'swift',
  path    => '/etc/swift',
  require => 'Package[swift]',
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

file { '/etc/xinetd.d/rsync':
  ensure  => 'present',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

service rsync
{
        port            = 873
        disable         = no
        socket_type     = stream
        protocol        = tcp
        wait            = no
        user            = root
        group           = root
        groups          = yes
        server          = /usr/bin/rsync
        bind            = 192.168.1.2
        server_args     = --daemon --config /etc/rsyncd.conf
        per_source      = UNLIMITED
        cps             = 512 10
        flags           = IPv4
}
',
  mode    => '0644',
  notify  => 'Service[xinetd]',
  owner   => 'root',
  path    => '/etc/xinetd.d/rsync',
  require => 'File[/etc/xinetd.d]',
}

file { '/etc/xinetd.d/swiftcheck':
  ensure  => 'present',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

service swiftcheck
{
        port            = 49001
        disable         = no
        socket_type     = stream
        protocol        = tcp
        wait            = no
        user            = nobody
        group           = nogroup
        groups          = yes
        server          = /usr/bin/swiftcheck
        bind            = 0.0.0.0
        server_args     = http://192.168.0.2:8080 192.168.0.2 5
        only_from       = 127.0.0.1 240.0.0.2 192.168.1.0/24 192.168.0.0/24
        per_source      = UNLIMITED
        cps             = 512 10
        flags           = IPv4
}
',
  mode    => '0644',
  notify  => 'Service[xinetd]',
  owner   => 'root',
  path    => '/etc/xinetd.d/swiftcheck',
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

file { '/srv/node':
  ensure       => 'directory',
  group        => 'swift',
  owner        => 'swift',
  path         => '/srv/node',
  recurse      => 'true',
  recurselimit => '1',
}

file { '/tmp//_etc_rsyncd.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_rsyncd.conf/fragments.concat.out',
}

file { '/tmp//_etc_rsyncd.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_rsyncd.conf/fragments.concat',
}

file { '/tmp//_etc_rsyncd.conf/fragments/00_header_rsyncd_conf_header':
  ensure  => 'file',
  alias   => 'concat_fragment_rsyncd_conf_header',
  backup  => 'puppet',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

pid file = /var/run/rsyncd.pid
uid = nobody
gid = nobody
use chroot = no
log format = %t %a %m %f %b
syslog facility = local3
timeout = 300
address = 192.168.1.2
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/rsyncd.conf]',
  path    => '/tmp//_etc_rsyncd.conf/fragments/00_header_rsyncd_conf_header',
  replace => 'true',
}

file { '/tmp//_etc_rsyncd.conf/fragments/10_account_frag-account':
  ensure  => 'file',
  alias   => 'concat_fragment_frag-account',
  backup  => 'puppet',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

[ account ]
path            = /srv/node
read only       = false
write only      = no
list            = yes
uid             = swift
gid             = swift
incoming chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
outgoing chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
max connections = 25
lock file       = /var/lock/account.lock
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/rsyncd.conf]',
  path    => '/tmp//_etc_rsyncd.conf/fragments/10_account_frag-account',
  replace => 'true',
}

file { '/tmp//_etc_rsyncd.conf/fragments/10_container_frag-container':
  ensure  => 'file',
  alias   => 'concat_fragment_frag-container',
  backup  => 'puppet',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

[ container ]
path            = /srv/node
read only       = false
write only      = no
list            = yes
uid             = swift
gid             = swift
incoming chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
outgoing chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
max connections = 25
lock file       = /var/lock/container.lock
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/rsyncd.conf]',
  path    => '/tmp//_etc_rsyncd.conf/fragments/10_container_frag-container',
  replace => 'true',
}

file { '/tmp//_etc_rsyncd.conf/fragments/10_object_frag-object':
  ensure  => 'file',
  alias   => 'concat_fragment_frag-object',
  backup  => 'puppet',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

[ object ]
path            = /srv/node
read only       = false
write only      = no
list            = yes
uid             = swift
gid             = swift
incoming chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
outgoing chmod  = Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r
max connections = 25
lock file       = /var/lock/object.lock
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/rsyncd.conf]',
  path    => '/tmp//_etc_rsyncd.conf/fragments/10_object_frag-object',
  replace => 'true',
}

file { '/tmp//_etc_rsyncd.conf/fragments/10_swift_server_frag-swift_server':
  ensure  => 'file',
  alias   => 'concat_fragment_frag-swift_server',
  backup  => 'puppet',
  content => '# This file is being maintained by Puppet.
# DO NOT EDIT

[ swift_server ]
path            = /etc/swift
read only       = true
write only      = no
list            = yes
uid             = swift
gid             = swift
incoming chmod  = 0644
outgoing chmod  = 0644
max connections = 5
lock file       = /var/lock/swift_server.lock
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/rsyncd.conf]',
  path    => '/tmp//_etc_rsyncd.conf/fragments/10_swift_server_frag-swift_server',
  replace => 'true',
}

file { '/tmp//_etc_rsyncd.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/rsyncd.conf]',
  path    => '/tmp//_etc_rsyncd.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_rsyncd.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_rsyncd.conf',
}

file { '/tmp//_etc_swift_account-server.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_swift_account-server.conf/fragments.concat.out',
}

file { '/tmp//_etc_swift_account-server.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_swift_account-server.conf/fragments.concat',
}

file { '/tmp//_etc_swift_account-server.conf/fragments/00_swift-account-6002':
  ensure  => 'file',
  alias   => 'concat_fragment_swift-account-6002',
  backup  => 'puppet',
  content => '[DEFAULT]
devices = /srv/node
bind_ip = 192.168.1.2
bind_port = 6002
mount_check = false
user = swift
workers = 1
log_name = swift-account-server
log_facility = LOG_SYSLOG
log_level = INFO
log_address = /dev/log



[pipeline:main]
pipeline = account-server

[app:account-server]
use = egg:swift#account
set log_name = swift-account-server
set log_facility = LOG_SYSLOG
set log_level = INFO
set log_requests = true
set log_address = /dev/log

[account-replicator]
concurrency = 4

[account-auditor]

[account-reaper]
concurrency = 4
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/account-server.conf]',
  path    => '/tmp//_etc_swift_account-server.conf/fragments/00_swift-account-6002',
  replace => 'true',
}

file { '/tmp//_etc_swift_account-server.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/swift/account-server.conf]',
  path    => '/tmp//_etc_swift_account-server.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_swift_account-server.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_swift_account-server.conf',
}

file { '/tmp//_etc_swift_container-server.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_swift_container-server.conf/fragments.concat.out',
}

file { '/tmp//_etc_swift_container-server.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_swift_container-server.conf/fragments.concat',
}

file { '/tmp//_etc_swift_container-server.conf/fragments/00_swift-container-6001':
  ensure  => 'file',
  alias   => 'concat_fragment_swift-container-6001',
  backup  => 'puppet',
  content => '[DEFAULT]
devices = /srv/node
bind_ip = 192.168.1.2
bind_port = 6001
mount_check = false
user = swift
log_name = swift-container-server
log_facility = LOG_SYSLOG
log_level = INFO
log_address = /dev/log


workers = 1
allowed_sync_hosts = 127.0.0.1

[pipeline:main]
pipeline = container-server

[app:container-server]
allow_versions = true
use = egg:swift#container
set log_name = swift-container-server
set log_facility = LOG_SYSLOG
set log_level = INFO
set log_requests = true
set log_address = /dev/log

[container-replicator]
concurrency = 4

[container-updater]
concurrency = 4

[container-auditor]

[container-sync]
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/container-server.conf]',
  path    => '/tmp//_etc_swift_container-server.conf/fragments/00_swift-container-6001',
  replace => 'true',
}

file { '/tmp//_etc_swift_container-server.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/swift/container-server.conf]',
  path    => '/tmp//_etc_swift_container-server.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_swift_container-server.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_swift_container-server.conf',
}

file { '/tmp//_etc_swift_object-server.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_swift_object-server.conf/fragments.concat.out',
}

file { '/tmp//_etc_swift_object-server.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_swift_object-server.conf/fragments.concat',
}

file { '/tmp//_etc_swift_object-server.conf/fragments/00_swift-object-6000':
  ensure  => 'file',
  alias   => 'concat_fragment_swift-object-6000',
  backup  => 'puppet',
  content => '[DEFAULT]
devices = /srv/node
bind_ip = 192.168.1.2
bind_port = 6000
mount_check = false
user = swift
log_name = swift-object-server
log_facility = LOG_SYSLOG
log_level = INFO
log_address = /dev/log


workers = 1

[pipeline:main]
pipeline = object-server

[app:object-server]
use = egg:swift#object
set log_name = swift-object-server
set log_facility = LOG_SYSLOG
set log_level = INFO
set log_requests = true
set log_address = /dev/log

[object-replicator]
concurrency = 4

[object-updater]
concurrency = 4

[object-auditor]
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/object-server.conf]',
  path    => '/tmp//_etc_swift_object-server.conf/fragments/00_swift-object-6000',
  replace => 'true',
}

file { '/tmp//_etc_swift_object-server.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/swift/object-server.conf]',
  path    => '/tmp//_etc_swift_object-server.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_swift_object-server.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_swift_object-server.conf',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_swift_proxy-server.conf/fragments.concat.out',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_swift_proxy-server.conf/fragments.concat',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/00_swift_proxy':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_proxy',
  backup  => 'puppet',
  content => '# This file is managed by puppet.  Do not edit
#
[DEFAULT]
bind_port = 8080

bind_ip = 192.168.0.2

workers = 4
user = swift
log_name = swift-proxy-server
log_facility = LOG_SYSLOG
log_level = INFO
log_headers = False
log_address = /dev/log



[pipeline:main]
pipeline = catch_errors crossdomain healthcheck cache bulk tempurl ratelimit formpost swift3 s3token authtoken keystone staticweb container_quotas account_quotas slo proxy-server

[app:proxy-server]
use = egg:swift#proxy
set log_name = swift-proxy-server
set log_facility = LOG_SYSLOG
set log_level = INFO
set log_address = /dev/log
log_handoffs = true
allow_account_management = true
account_autocreate = true




',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/00_swift_proxy',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/21_swift_bulk':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_bulk',
  backup  => 'puppet',
  content => '
[filter:bulk]
use = egg:swift#bulk
max_containers_per_extraction = 10000
max_failed_extractions = 1000
max_deletes_per_request = 10000
yield_frequency = 60
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/21_swift_bulk',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/22_swift_authtoken':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_authtoken',
  backup  => 'puppet',
  content => '
[filter:authtoken]
log_name = swift
signing_dir = /var/cache/swift
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

auth_host = 192.168.0.2
auth_port = 35357
auth_protocol = http
auth_uri = http://192.168.0.2:5000
admin_tenant_name = services
admin_user = swift
admin_password = BP92J6tg
delay_auth_decision = 1
cache = swift.cache
include_service_catalog = False
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/22_swift_authtoken',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/23_swift_cache':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_cache',
  backup  => 'puppet',
  content => '
[filter:cache]
use = egg:swift#memcache
memcache_servers = 192.168.0.2:11211,192.168.0.3:11211,192.168.0.4:11211
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/23_swift_cache',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/24_swift_catch_errors':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_catch_errors',
  backup  => 'puppet',
  content => '
[filter:catch_errors]
use = egg:swift#catch_errors
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/24_swift_catch_errors',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/25_swift_healthcheck':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_healthcheck',
  backup  => 'puppet',
  content => '
[filter:healthcheck]
use = egg:swift#healthcheck
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/25_swift_healthcheck',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/26_swift_ratelimit':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_ratelimit',
  backup  => 'puppet',
  content => '
[filter:ratelimit]
use = egg:swift#ratelimit
clock_accuracy = 1000
max_sleep_time_seconds = 60
log_sleep_time_seconds = 0
rate_buffer_seconds = 5
account_ratelimit = 0
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/26_swift_ratelimit',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/27_swift_swift3':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_swift3',
  backup  => 'puppet',
  content => '
[filter:swift3]
use = egg:swift3#swift3
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/27_swift_swift3',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/28_swift_s3token':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_s3token',
  backup  => 'puppet',
  content => '
[filter:s3token]
paste.filter_factory = keystonemiddleware.s3_token:filter_factory
auth_port = 35357
auth_protocol = http
auth_host = 192.168.0.2
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/28_swift_s3token',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/29_swift-proxy-tempurl':
  ensure  => 'file',
  alias   => 'concat_fragment_swift-proxy-tempurl',
  backup  => 'puppet',
  content => '
[filter:tempurl]
use = egg:swift#tempurl
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/29_swift-proxy-tempurl',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/31_swift-proxy-formpost':
  ensure  => 'file',
  alias   => 'concat_fragment_swift-proxy-formpost',
  backup  => 'puppet',
  content => '
[filter:formpost]
use = egg:swift#formpost
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/31_swift-proxy-formpost',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/32_swift-proxy-staticweb':
  ensure  => 'file',
  alias   => 'concat_fragment_swift-proxy-staticweb',
  backup  => 'puppet',
  content => '
[filter:staticweb]
use = egg:swift#staticweb
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/32_swift-proxy-staticweb',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/35_swift_crossdomain':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_crossdomain',
  backup  => 'puppet',
  content => '
[filter:crossdomain]
use = egg:swift#crossdomain
cross_domain_policy = <allow-access-from domain="*" secure="false" />
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/35_swift_crossdomain',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/35_swift_slo':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_slo',
  backup  => 'puppet',
  content => '
[filter:slo]
use = egg:swift#slo
max_manifest_segments = 1000
max_manifest_size = 2097152
min_segment_size = 1048576
rate_limit_after_segment = 10
rate_limit_segments_per_sec = 0
max_get_time = 86400
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/35_swift_slo',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/79_swift_keystone':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_keystone',
  backup  => 'puppet',
  content => '
[filter:keystone]
use = egg:swift#keystoneauth
operator_roles = admin, SwiftOperator
is_admin = true
reseller_prefix = AUTH_
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/79_swift_keystone',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/80_swift_account_quotas':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_account_quotas',
  backup  => 'puppet',
  content => '
[filter:account_quotas]
use = egg:swift#account_quotas
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/80_swift_account_quotas',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments/81_swift_container_quotas':
  ensure  => 'file',
  alias   => 'concat_fragment_swift_container_quotas',
  backup  => 'puppet',
  content => '
[filter:container_quotas]
use = egg:swift#container_quotas
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments/81_swift_container_quotas',
  replace => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/swift/proxy-server.conf]',
  path    => '/tmp//_etc_swift_proxy-server.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_swift_proxy-server.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_swift_proxy-server.conf',
}

file { '/tmp//bin/concatfragments.rb':
  ensure => 'file',
  mode   => '0755',
  path   => '/tmp//bin/concatfragments.rb',
  source => 'puppet:///modules/concat/concatfragments.rb',
}

file { '/tmp//bin':
  ensure => 'directory',
  mode   => '0755',
  path   => '/tmp//bin',
}

file { '/tmp/':
  ensure => 'directory',
  mode   => '0755',
  path   => '/tmp',
}

file { '/var/cache/swift':
  ensure                  => 'directory',
  group                   => 'swift',
  mode                    => '0700',
  owner                   => 'swift',
  path                    => '/var/cache/swift',
  selinux_ignore_defaults => 'true',
}

file { '/var/lib/swift':
  ensure  => 'directory',
  group   => 'swift',
  owner   => 'swift',
  path    => '/var/lib/swift',
  require => 'Package[swift]',
}

file { '/var/run/swift':
  ensure                  => 'directory',
  group                   => 'swift',
  owner                   => 'swift',
  path                    => '/var/run/swift',
  require                 => 'Package[swift]',
  selinux_ignore_defaults => 'true',
}

openstack::swift::storage_node::device_directory { '1':
  devices => '/srv/node',
  name    => '1',
}

openstack::swift::storage_node::device_directory { '2':
  devices => '/srv/node',
  name    => '2',
}

package { 'python-keystone':
  ensure => 'present',
  name   => 'python-keystone',
}

package { 'rsync':
  ensure => 'installed',
  name   => 'rsync',
}

package { 'swift-account':
  ensure => 'present',
  before => ['Service[swift-account]', 'Service[swift-account-replicator]'],
  name   => 'swift-account',
  tag    => ['openstack', 'swift-package'],
}

package { 'swift-container':
  ensure => 'present',
  before => ['Service[swift-container]', 'Service[swift-container-replicator]'],
  name   => 'swift-container',
  tag    => ['openstack', 'swift-package'],
}

package { 'swift-object':
  ensure => 'present',
  before => ['Service[swift-object]', 'Service[swift-object-replicator]'],
  name   => 'swift-object',
  tag    => ['openstack', 'swift-package'],
}

package { 'swift-plugin-s3':
  ensure => 'present',
  name   => 'swift-plugin-s3',
  tag    => 'openstack',
}

package { 'swift-proxy':
  ensure => 'present',
  name   => 'swift-proxy',
  tag    => ['openstack', 'swift-package'],
}

package { 'swift':
  ensure => 'present',
  name   => 'swift',
  tag    => ['openstack', 'swift-package'],
}

package { 'swiftclient':
  ensure => 'present',
  name   => 'python-swiftclient',
  tag    => 'openstack',
}

package { 'xinetd':
  ensure => 'installed',
  before => 'Service[xinetd]',
  name   => 'xinetd',
}

ring_devices { 'all':
  name     => 'all',
  notify   => ['Swift::Ringbuilder::Rebalance[object]', 'Swift::Ringbuilder::Rebalance[account]', 'Swift::Ringbuilder::Rebalance[container]'],
  require  => 'Class[Swift]',
  storages => {'node-128' => {'fqdn' => 'node-128.test.domain.local', 'name' => 'node-128', 'node_roles' => ['primary-controller'], 'storage_address' => '192.168.1.2', 'swift_zone' => '1', 'uid' => '128', 'user_node_name' => 'Untitled (6a:e7)'}, 'node-129' => {'fqdn' => 'node-129.test.domain.local', 'name' => 'node-129', 'node_roles' => ['controller'], 'storage_address' => '192.168.1.3', 'swift_zone' => '1', 'uid' => '129', 'user_node_name' => 'Untitled (6a:e7)'}, 'node-131' => {'fqdn' => 'node-131.test.domain.local', 'name' => 'node-131', 'node_roles' => ['controller'], 'storage_address' => '192.168.1.4', 'swift_zone' => '1', 'uid' => '131', 'user_node_name' => 'Untitled (6a:e7)'}},
}

rsync::server::module { 'account':
  gid             => 'swift',
  incoming_chmod  => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  list            => 'yes',
  lock_file       => '/var/lock/account.lock',
  max_connections => '25',
  name            => 'account',
  order           => '10_account',
  outgoing_chmod  => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  path            => '/srv/node',
  read_only       => 'false',
  uid             => 'swift',
  write_only      => 'no',
}

rsync::server::module { 'container':
  gid             => 'swift',
  incoming_chmod  => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  list            => 'yes',
  lock_file       => '/var/lock/container.lock',
  max_connections => '25',
  name            => 'container',
  order           => '10_container',
  outgoing_chmod  => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  path            => '/srv/node',
  read_only       => 'false',
  uid             => 'swift',
  write_only      => 'no',
}

rsync::server::module { 'object':
  gid             => 'swift',
  incoming_chmod  => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  list            => 'yes',
  lock_file       => '/var/lock/object.lock',
  max_connections => '25',
  name            => 'object',
  order           => '10_object',
  outgoing_chmod  => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  path            => '/srv/node',
  read_only       => 'false',
  uid             => 'swift',
  write_only      => 'no',
}

rsync::server::module { 'swift_server':
  gid             => 'swift',
  incoming_chmod  => '0644',
  list            => 'yes',
  lock_file       => '/var/lock/swift_server.lock',
  max_connections => '5',
  name            => 'swift_server',
  order           => '10_swift_server',
  outgoing_chmod  => '0644',
  path            => '/etc/swift',
  read_only       => 'true',
  uid             => 'swift',
  write_only      => 'no',
}

service { 'swift-account-auditor':
  ensure   => 'running',
  before   => 'Class[Swift::Dispersion]',
  enable   => 'true',
  name     => 'swift-account-auditor',
  provider => 'upstart',
  require  => 'Package[swift-account]',
  tag      => 'swift-service',
}

service { 'swift-account-reaper':
  ensure   => 'running',
  before   => 'Class[Swift::Dispersion]',
  enable   => 'true',
  name     => 'swift-account-reaper',
  provider => 'upstart',
  require  => 'Package[swift-account]',
  tag      => 'swift-service',
}

service { 'swift-account-replicator':
  ensure    => 'running',
  before    => 'Class[Swift::Dispersion]',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'swift-account-replicator',
  provider  => 'upstart',
  subscribe => 'Package[swift-account]',
  tag       => 'swift-service',
}

service { 'swift-account':
  ensure    => 'running',
  before    => 'Class[Swift::Dispersion]',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'swift-account',
  provider  => 'upstart',
  subscribe => 'Package[swift-account]',
  tag       => 'swift-service',
}

service { 'swift-container-auditor':
  ensure   => 'running',
  before   => 'Class[Swift::Dispersion]',
  enable   => 'true',
  name     => 'swift-container-auditor',
  provider => 'upstart',
  require  => 'Package[swift-container]',
  tag      => 'swift-service',
}

service { 'swift-container-replicator':
  ensure    => 'running',
  before    => 'Class[Swift::Dispersion]',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'swift-container-replicator',
  provider  => 'upstart',
  subscribe => 'Package[swift-container]',
  tag       => 'swift-service',
}

service { 'swift-container-sync':
  ensure   => 'running',
  enable   => 'true',
  name     => 'swift-container-sync',
  provider => 'upstart',
  require  => 'File[/etc/init/swift-container-sync.conf]',
}

service { 'swift-container-updater':
  ensure   => 'running',
  before   => 'Class[Swift::Dispersion]',
  enable   => 'true',
  name     => 'swift-container-updater',
  provider => 'upstart',
  require  => 'Package[swift-container]',
  tag      => 'swift-service',
}

service { 'swift-container':
  ensure    => 'running',
  before    => 'Class[Swift::Dispersion]',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'swift-container',
  provider  => 'upstart',
  subscribe => 'Package[swift-container]',
  tag       => 'swift-service',
}

service { 'swift-object-auditor':
  ensure   => 'running',
  before   => 'Class[Swift::Dispersion]',
  enable   => 'true',
  name     => 'swift-object-auditor',
  provider => 'upstart',
  require  => 'Package[swift-object]',
  tag      => 'swift-service',
}

service { 'swift-object-replicator':
  ensure    => 'running',
  before    => 'Class[Swift::Dispersion]',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'swift-object-replicator',
  provider  => 'upstart',
  subscribe => 'Package[swift-object]',
  tag       => 'swift-service',
}

service { 'swift-object-updater':
  ensure   => 'running',
  before   => 'Class[Swift::Dispersion]',
  enable   => 'true',
  name     => 'swift-object-updater',
  provider => 'upstart',
  require  => 'Package[swift-object]',
  tag      => 'swift-service',
}

service { 'swift-object':
  ensure    => 'running',
  before    => 'Class[Swift::Dispersion]',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'swift-object',
  provider  => 'upstart',
  subscribe => 'Package[swift-object]',
  tag       => 'swift-service',
}

service { 'swift-proxy':
  ensure    => 'running',
  before    => 'Class[Swift::Dispersion]',
  enable    => 'true',
  hasstatus => 'true',
  name      => 'swift-proxy',
  provider  => 'upstart',
  subscribe => 'Concat[/etc/swift/proxy-server.conf]',
  tag       => 'swift-service',
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

swift::ringbuilder::create { 'account':
  before         => 'Ring_devices[all]',
  min_part_hours => '1',
  name           => 'account',
  part_power     => '10',
  replicas       => '3',
}

swift::ringbuilder::create { 'container':
  before         => 'Ring_devices[all]',
  min_part_hours => '1',
  name           => 'container',
  part_power     => '10',
  replicas       => '3',
}

swift::ringbuilder::create { 'object':
  before         => 'Ring_devices[all]',
  min_part_hours => '1',
  name           => 'object',
  part_power     => '10',
  replicas       => '3',
}

swift::ringbuilder::rebalance { 'account':
  before => ['Service[swift-proxy]', 'Swift::Storage::Generic[account]', 'Swift::Storage::Generic[container]', 'Swift::Storage::Generic[object]'],
  name   => 'account',
}

swift::ringbuilder::rebalance { 'container':
  before => ['Service[swift-proxy]', 'Swift::Storage::Generic[account]', 'Swift::Storage::Generic[container]', 'Swift::Storage::Generic[object]'],
  name   => 'container',
}

swift::ringbuilder::rebalance { 'object':
  before => ['Service[swift-proxy]', 'Swift::Storage::Generic[account]', 'Swift::Storage::Generic[container]', 'Swift::Storage::Generic[object]'],
  name   => 'object',
}

swift::storage::generic { 'account':
  enabled          => 'true',
  manage_service   => 'true',
  name             => 'account',
  package_ensure   => 'present',
  service_provider => 'upstart',
}

swift::storage::generic { 'container':
  enabled          => 'true',
  manage_service   => 'true',
  name             => 'container',
  package_ensure   => 'present',
  service_provider => 'upstart',
}

swift::storage::generic { 'object':
  enabled          => 'true',
  manage_service   => 'true',
  name             => 'object',
  package_ensure   => 'present',
  service_provider => 'upstart',
}

swift::storage::server { '6000':
  allow_versions         => 'false',
  config_file_path       => 'object-server.conf',
  devices                => '/srv/node',
  group                  => 'swift',
  incoming_chmod         => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  log_address            => '/dev/log',
  log_facility           => 'LOG_SYSLOG',
  log_level              => 'INFO',
  log_name               => 'swift-object-server',
  log_requests           => 'true',
  max_connections        => '25',
  mount_check            => 'false',
  name                   => '6000',
  outgoing_chmod         => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  owner                  => 'swift',
  pipeline               => 'object-server',
  reaper_concurrency     => '4',
  replicator_concurrency => '4',
  storage_local_net_ip   => '192.168.1.2',
  type                   => 'object',
  updater_concurrency    => '4',
  user                   => 'swift',
  workers                => '1',
}

swift::storage::server { '6001':
  allow_versions         => 'true',
  config_file_path       => 'container-server.conf',
  devices                => '/srv/node',
  group                  => 'swift',
  incoming_chmod         => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  log_address            => '/dev/log',
  log_facility           => 'LOG_SYSLOG',
  log_level              => 'INFO',
  log_name               => 'swift-container-server',
  log_requests           => 'true',
  max_connections        => '25',
  mount_check            => 'false',
  name                   => '6001',
  outgoing_chmod         => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  owner                  => 'swift',
  pipeline               => 'container-server',
  reaper_concurrency     => '4',
  replicator_concurrency => '4',
  storage_local_net_ip   => '192.168.1.2',
  type                   => 'container',
  updater_concurrency    => '4',
  user                   => 'swift',
  workers                => '1',
}

swift::storage::server { '6002':
  allow_versions         => 'false',
  config_file_path       => 'account-server.conf',
  devices                => '/srv/node',
  group                  => 'swift',
  incoming_chmod         => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  log_address            => '/dev/log',
  log_facility           => 'LOG_SYSLOG',
  log_level              => 'INFO',
  log_name               => 'swift-account-server',
  log_requests           => 'true',
  max_connections        => '25',
  mount_check            => 'false',
  name                   => '6002',
  outgoing_chmod         => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  owner                  => 'swift',
  pipeline               => 'account-server',
  reaper_concurrency     => '4',
  replicator_concurrency => '4',
  storage_local_net_ip   => '192.168.1.2',
  type                   => 'account',
  updater_concurrency    => '4',
  user                   => 'swift',
  workers                => '1',
}

swift_config { 'swift-constraints/max_header_size':
  name   => 'swift-constraints/max_header_size',
  notify => ['Service[swift-proxy]', 'Service[swift-account-reaper]', 'Service[swift-account-auditor]', 'Service[swift-container-updater]', 'Service[swift-container-auditor]', 'Service[swift-container-sync]', 'Service[swift-object-updater]', 'Service[swift-object-auditor]', 'Service[swift-account]', 'Service[swift-container]', 'Service[swift-object]'],
  value  => '32768',
}

swift_config { 'swift-hash/swift_hash_path_suffix':
  name   => 'swift-hash/swift_hash_path_suffix',
  notify => ['Service[swift-proxy]', 'Service[swift-account-reaper]', 'Service[swift-account-auditor]', 'Service[swift-container-updater]', 'Service[swift-container-auditor]', 'Service[swift-container-sync]', 'Service[swift-object-updater]', 'Service[swift-object-auditor]', 'Service[swift-account]', 'Service[swift-container]', 'Service[swift-object]'],
  value  => 'swift_secret',
}

swift_dispersion_config { 'dispersion/auth_key':
  name   => 'dispersion/auth_key',
  notify => 'Exec[swift-dispersion-populate]',
  value  => 'BP92J6tg',
}

swift_dispersion_config { 'dispersion/auth_url':
  name   => 'dispersion/auth_url',
  notify => 'Exec[swift-dispersion-populate]',
  value  => 'http://192.168.0.2:5000/v2.0/',
}

swift_dispersion_config { 'dispersion/auth_user':
  name   => 'dispersion/auth_user',
  notify => 'Exec[swift-dispersion-populate]',
  value  => 'services:swift',
}

swift_dispersion_config { 'dispersion/auth_version':
  name   => 'dispersion/auth_version',
  notify => 'Exec[swift-dispersion-populate]',
  value  => '2.0',
}

swift_dispersion_config { 'dispersion/concurrency':
  name   => 'dispersion/concurrency',
  notify => 'Exec[swift-dispersion-populate]',
  value  => '25',
}

swift_dispersion_config { 'dispersion/dispersion_coverage':
  name   => 'dispersion/dispersion_coverage',
  notify => 'Exec[swift-dispersion-populate]',
  value  => '1',
}

swift_dispersion_config { 'dispersion/dump_json':
  name   => 'dispersion/dump_json',
  notify => 'Exec[swift-dispersion-populate]',
  value  => 'no',
}

swift_dispersion_config { 'dispersion/endpoint_type':
  name   => 'dispersion/endpoint_type',
  notify => 'Exec[swift-dispersion-populate]',
  value  => 'publicURL',
}

swift_dispersion_config { 'dispersion/retries':
  name   => 'dispersion/retries',
  notify => 'Exec[swift-dispersion-populate]',
  value  => '5',
}

swift_dispersion_config { 'dispersion/swift_dir':
  name   => 'dispersion/swift_dir',
  notify => 'Exec[swift-dispersion-populate]',
  value  => '/etc/swift',
}

user { 'swift':
  ensure => 'present',
  name   => 'swift',
}

xinetd::service { 'rsync':
  ensure                  => 'present',
  bind                    => '192.168.1.2',
  cps                     => '512 10',
  disable                 => 'no',
  flags                   => 'IPv4',
  group                   => 'root',
  groups                  => 'yes',
  instances               => 'UNLIMITED',
  log_on_failure_operator => '+=',
  log_on_success_operator => '+=',
  name                    => 'rsync',
  per_source              => 'UNLIMITED',
  port                    => '873',
  protocol                => 'tcp',
  require                 => 'Package[rsync]',
  server                  => '/usr/bin/rsync',
  server_args             => '--daemon --config /etc/rsyncd.conf',
  service_name            => 'rsync',
  socket_type             => 'stream',
  user                    => 'root',
}

xinetd::service { 'swiftcheck':
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
  name                    => 'swiftcheck',
  only_from               => '127.0.0.1 240.0.0.2 192.168.1.0/24 192.168.0.0/24',
  per_source              => 'UNLIMITED',
  port                    => '49001',
  protocol                => 'tcp',
  require                 => 'Augeas[swiftcheck]',
  server                  => '/usr/bin/swiftcheck',
  server_args             => 'http://192.168.0.2:8080 192.168.0.2 5',
  service_name            => 'swiftcheck',
  socket_type             => 'stream',
  user                    => 'nobody',
}

