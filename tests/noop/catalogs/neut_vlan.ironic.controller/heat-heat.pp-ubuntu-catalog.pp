class { 'Heat::Api':
  bind_host      => '192.168.0.3',
  bind_port      => '8004',
  cert_file      => 'false',
  enabled        => 'true',
  key_file       => 'false',
  manage_service => 'true',
  name           => 'Heat::Api',
  package_ensure => 'present',
  use_ssl        => 'false',
  workers        => '0',
}

class { 'Heat::Api_cfn':
  bind_host      => '192.168.0.3',
  bind_port      => '8000',
  cert_file      => 'false',
  enabled        => 'true',
  key_file       => 'false',
  manage_service => 'true',
  name           => 'Heat::Api_cfn',
  package_ensure => 'present',
  use_ssl        => 'false',
  workers        => '0',
}

class { 'Heat::Api_cloudwatch':
  bind_host      => '192.168.0.3',
  bind_port      => '8003',
  cert_file      => 'false',
  enabled        => 'true',
  key_file       => 'false',
  manage_service => 'true',
  name           => 'Heat::Api_cloudwatch',
  package_ensure => 'present',
  use_ssl        => 'false',
  workers        => '0',
}

class { 'Heat::Client':
  ensure => 'present',
  name   => 'Heat::Client',
}

class { 'Heat::Db::Sync':
  name => 'Heat::Db::Sync',
}

class { 'Heat::Docker_resource':
  enabled      => 'true',
  name         => 'Heat::Docker_resource',
  package_name => 'heat-docker',
}

class { 'Heat::Engine':
  auth_encryption_key                 => 'ce489de3a39996b694db7c8d4804a93d',
  default_deployment_signal_transport => 'CFN_SIGNAL',
  default_software_config_transport   => 'POLL_SERVER_CFN',
  deferred_auth_method                => 'trusts',
  enabled                             => 'true',
  engine_life_check_timeout           => '2',
  heat_metadata_server_url            => 'http://192.168.0.2:8000',
  heat_stack_user_role                => 'heat_stack_user',
  heat_waitcondition_server_url       => 'http://192.168.0.2:8000/v1/waitcondition',
  heat_watch_server_url               => 'http://192.168.0.2:8003',
  manage_service                      => 'true',
  name                                => 'Heat::Engine',
  package_ensure                      => 'present',
  trusts_delegated_roles              => [],
}

class { 'Heat::Keystone::Domain':
  auth_url           => 'http://192.168.0.2:35357/v2.0',
  domain_admin       => 'heat_admin',
  domain_admin_email => 'heat_admin@localhost',
  domain_name        => 'heat',
  domain_password    => 'CxKs9UObDHZOgw20Gv3kwtGT',
  keystone_admin     => 'heat',
  keystone_password  => 'CxKs9UObDHZOgw20Gv3kwtGT',
  keystone_tenant    => 'services',
  manage_domain      => 'true',
  name               => 'Heat::Keystone::Domain',
  notify             => 'Service[heat-engine]',
}

class { 'Heat::Params':
  name => 'Heat::Params',
}

class { 'Heat::Policy':
  before      => ['Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  name        => 'Heat::Policy',
  policies    => {},
  policy_path => '/etc/heat/policy.json',
}

class { 'Heat':
  amqp_durable_queues                => 'false',
  auth_uri                           => 'false',
  before                             => 'Haproxy_backend_status[keystone-admin]',
  database_connection                => 'sqlite:////var/lib/heat/heat.sqlite',
  database_idle_timeout              => '3600',
  debug                              => 'false',
  identity_uri                       => 'false',
  keystone_ec2_uri                   => 'http://192.168.0.2:5000/v2.0',
  keystone_host                      => '192.168.0.2',
  keystone_password                  => 'CxKs9UObDHZOgw20Gv3kwtGT',
  keystone_port                      => '35357',
  keystone_protocol                  => 'http',
  keystone_tenant                    => 'services',
  keystone_user                      => 'heat',
  kombu_ssl_version                  => 'TLSv1',
  log_dir                            => '/var/log/heat',
  log_facility                       => 'LOG_LOCAL0',
  name                               => 'Heat',
  package_ensure                     => 'present',
  qpid_heartbeat                     => '60',
  qpid_hostname                      => 'localhost',
  qpid_password                      => 'guest',
  qpid_port                          => '5672',
  qpid_protocol                      => 'tcp',
  qpid_reconnect                     => 'true',
  qpid_reconnect_interval            => '0',
  qpid_reconnect_interval_max        => '0',
  qpid_reconnect_interval_min        => '0',
  qpid_reconnect_limit               => '0',
  qpid_reconnect_timeout             => '0',
  qpid_tcp_nodelay                   => 'true',
  qpid_username                      => 'guest',
  rabbit_heartbeat_rate              => '2',
  rabbit_heartbeat_timeout_threshold => '0',
  rabbit_host                        => '127.0.0.1',
  rabbit_hosts                       => '192.168.0.3:5673',
  rabbit_password                    => 'OLCrvt99FgutnBs63PeFJchF',
  rabbit_port                        => '5672',
  rabbit_use_ssl                     => 'false',
  rabbit_userid                      => 'nova',
  rabbit_virtual_host                => '/',
  region_name                        => 'RegionOne',
  require                            => ['Class[Mysql::Bindings]', 'Class[Mysql::Bindings::Python]'],
  rpc_backend                        => 'rabbit',
  rpc_response_timeout               => '600',
  sql_connection                     => 'mysql://heat:qugZa4RJl8iT0K7060f1buWM@192.168.0.2/heat?read_timeout=60',
  sync_db                            => 'true',
  use_stderr                         => 'false',
  use_syslog                         => 'true',
  verbose                            => 'true',
}

class { 'Heat_ha::Engine':
  name => 'Heat_ha::Engine',
}

class { 'Mysql::Bindings::Python':
  name => 'Mysql::Bindings::Python',
}

class { 'Mysql::Bindings':
  name => 'Mysql::Bindings',
}

class { 'Mysql::Config':
  name => 'Mysql::Config',
}

class { 'Mysql::Params':
  name => 'Mysql::Params',
}

class { 'Mysql::Python':
  name           => 'Mysql::Python',
  package_ensure => 'present',
  package_name   => 'python-mysqldb',
}

class { 'Mysql::Server':
  name => 'Mysql::Server',
}

class { 'Openstack::Heat':
  amqp_hosts                    => '192.168.0.3:5673',
  amqp_password                 => 'OLCrvt99FgutnBs63PeFJchF',
  amqp_user                     => 'nova',
  api_bind_host                 => '192.168.0.3',
  api_bind_port                 => '8004',
  api_cfn_bind_host             => '192.168.0.3',
  api_cfn_bind_port             => '8000',
  api_cloudwatch_bind_host      => '192.168.0.3',
  api_cloudwatch_bind_port      => '8003',
  auth_encryption_key           => 'ce489de3a39996b694db7c8d4804a93d',
  auth_uri                      => 'false',
  db_allowed_hosts              => ['localhost', '%'],
  db_host                       => '192.168.0.2',
  db_name                       => 'heat',
  db_password                   => 'qugZa4RJl8iT0K7060f1buWM',
  db_user                       => 'heat',
  debug                         => 'false',
  enabled                       => 'true',
  external_ip                   => '192.168.0.2',
  heat_metadata_server_url      => 'false',
  heat_stack_user_role          => 'heat_stack_user',
  heat_waitcondition_server_url => 'false',
  heat_watch_server_url         => 'false',
  ic_https_validate_certs       => '1',
  ic_is_secure                  => '0',
  idle_timeout                  => '3600',
  keystone_auth                 => 'true',
  keystone_ec2_uri              => 'http://192.168.0.2:5000/v2.0',
  keystone_host                 => '192.168.0.2',
  keystone_password             => 'CxKs9UObDHZOgw20Gv3kwtGT',
  keystone_port                 => '35357',
  keystone_protocol             => 'http',
  keystone_service_port         => '5000',
  keystone_tenant               => 'services',
  keystone_user                 => 'heat',
  log_dir                       => '/var/log/heat',
  max_overflow                  => '20',
  max_pool_size                 => '20',
  max_retries                   => '-1',
  name                          => 'Openstack::Heat',
  public_ssl                    => 'true',
  rabbit_virtualhost            => '/',
  region                        => 'RegionOne',
  rpc_backend                   => 'rabbit',
  sql_connection                => 'mysql://heat:qugZa4RJl8iT0K7060f1buWM@192.168.0.2/heat?read_timeout=60',
  syslog_log_facility           => 'LOG_LOCAL0',
  trusts_delegated_roles        => [],
  use_stderr                    => 'false',
  use_syslog                    => 'true',
  verbose                       => 'true',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cs_resource { 'p_heat-engine':
  ensure          => 'present',
  before          => 'Service[heat-engine]',
  complex_type    => 'clone',
  metadata        => {'migration-threshold' => '3', 'resource-stickiness' => '1'},
  ms_metadata     => {'interleave' => 'true'},
  name            => 'p_heat-engine',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '30'}, 'start' => {'timeout' => '60'}, 'stop' => {'timeout' => '60'}},
  primitive_class => 'ocf',
  primitive_type  => 'heat-engine',
  provided_by     => 'fuel',
}

exec { 'heat-dbsync':
  command     => 'heat-manage --config-file /etc/heat/heat.conf db_sync',
  logoutput   => 'on_failure',
  notify      => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  path        => '/usr/bin',
  refreshonly => 'true',
  user        => 'heat',
}

exec { 'remove_heat-api-cfn_override':
  before  => ['Service[heat-api-cfn]', 'Service[heat-api-cfn]'],
  command => 'rm -f /etc/init/heat-api-cfn.override',
  onlyif  => 'test -f /etc/init/heat-api-cfn.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_heat-api-cloudwatch_override':
  before  => ['Service[heat-api-cloudwatch]', 'Service[heat-api-cloudwatch]'],
  command => 'rm -f /etc/init/heat-api-cloudwatch.override',
  onlyif  => 'test -f /etc/init/heat-api-cloudwatch.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_heat-api_override':
  before  => ['Service[heat-api]', 'Service[heat-api]'],
  command => 'rm -f /etc/init/heat-api.override',
  onlyif  => 'test -f /etc/init/heat-api.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_heat-engine_override':
  before  => ['Service[heat-engine]', 'Service[heat-engine]'],
  command => 'rm -f /etc/init/heat-engine.override',
  onlyif  => 'test -f /etc/init/heat-engine.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'wait_for_heat_config':
  before   => ['Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]', 'Service[heat-engine]'],
  command  => 'sync && sleep 3',
  provider => 'shell',
}

file { '/etc/heat/':
  ensure  => 'directory',
  group   => 'heat',
  mode    => '0750',
  owner   => 'heat',
  path    => '/etc/heat',
  require => 'Package[heat-common]',
}

file { '/etc/heat/heat.conf':
  group   => 'heat',
  mode    => '0640',
  owner   => 'heat',
  path    => '/etc/heat/heat.conf',
  require => 'Package[heat-common]',
}

file { 'create_heat-api-cfn_override':
  ensure  => 'present',
  before  => ['Package[heat-api-cfn]', 'Package[heat-api-cfn]', 'Exec[remove_heat-api-cfn_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/heat-api-cfn.override',
}

file { 'create_heat-api-cloudwatch_override':
  ensure  => 'present',
  before  => ['Package[heat-api-cloudwatch]', 'Package[heat-api-cloudwatch]', 'Exec[remove_heat-api-cloudwatch_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/heat-api-cloudwatch.override',
}

file { 'create_heat-api_override':
  ensure  => 'present',
  before  => ['Package[heat-api]', 'Package[heat-api]', 'Exec[remove_heat-api_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/heat-api.override',
}

file { 'create_heat-engine_override':
  ensure  => 'present',
  before  => ['Package[heat-engine]', 'Package[heat-engine]', 'Exec[remove_heat-engine_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/heat-engine.override',
}

file { 'ocf_handler_heat-engine':
  ensure  => 'present',
  before  => 'Service[heat-engine]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='p_heat-engine'

# OCF Parameters

help() {
cat<<EOF
OCF wrapper for heat-engine Pacemaker primitive

Usage: ocf_handler_heat-engine [-dh] (action)

Options:
-d - Use set -x to debug the shell script
-h - Show this help

Main actions:
* start
* stop
* monitor
* meta-data
* validate-all

Multistate:
* promote
* demote
* notify

Migration:
* migrate_to
* migrate_from

Optional and unused:
* usage
* help
* status
* reload
* restart
* recover
EOF
}

red() {
  echo -e "\033[31m${1}\033[0m"
}

green() {
  echo -e "\033[32m${1}\033[0m"
}

blue() {
  echo -e "\033[34m${1}\033[0m"
}

ec2error() {
  case "${1}" in
    0) green 'Success' ;;
    1) red 'Error: Generic' ;;
    2) red 'Error: Arguments' ;;
    3) red 'Error: Unimplemented' ;;
    4) red 'Error: Permissions' ;;
    5) red 'Error: Installation' ;;
    6) red 'Error: Configuration' ;;
    7) blue 'Not Running' ;;
    8) green 'Master Running' ;;
    9) red 'Master Failed' ;;
    *) red "Unknown" ;;
  esac
}

DEBUG='0'
while getopts ':dh' opt; do
  case $opt in
    d)
      DEBUG='1'
      ;;
    h)
      help
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      help
      exit 1
      ;;
  esac
done

shift "$((OPTIND - 1))"

ACTION="${1}"

# set default action to monitor
if [ "${ACTION}" = '' ]; then
  ACTION='monitor'
fi

# alias status to monitor
if [ "${ACTION}" = 'status' ]; then
  ACTION='monitor'
fi

# view defined OCF parameters
if [ "${ACTION}" = 'params' ]; then
  env | grep 'OCF_'
  exit 0
fi

if [ "${DEBUG}" = '1' ]; then
  bash -x /usr/lib/ocf/resource.d/fuel/heat-engine "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/heat-engine "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_heat-engine',
}

group { 'heat':
  name    => 'heat',
  require => 'Package[heat-common]',
}

haproxy_backend_status { 'keystone-admin':
  before => 'Class[Heat::Keystone::Domain]',
  count  => '200',
  name   => 'keystone-2',
  step   => '6',
  url    => 'http://192.168.0.2:10000/;csv',
}

heat_config { 'DATABASE/max_overflow':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DATABASE/max_overflow',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '20',
}

heat_config { 'DATABASE/max_pool_size':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DATABASE/max_pool_size',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '20',
}

heat_config { 'DATABASE/max_retries':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DATABASE/max_retries',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '-1',
}

heat_config { 'DEFAULT/amqp_durable_queues':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/amqp_durable_queues',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'false',
}

heat_config { 'DEFAULT/auth_encryption_key':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/auth_encryption_key',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'ce489de3a39996b694db7c8d4804a93d',
}

heat_config { 'DEFAULT/debug':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/debug',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'false',
}

heat_config { 'DEFAULT/default_deployment_signal_transport':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/default_deployment_signal_transport',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'CFN_SIGNAL',
}

heat_config { 'DEFAULT/default_software_config_transport':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/default_software_config_transport',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'POLL_SERVER_CFN',
}

heat_config { 'DEFAULT/deferred_auth_method':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/deferred_auth_method',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'trusts',
}

heat_config { 'DEFAULT/enable_stack_abandon':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/enable_stack_abandon',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'DEFAULT/enable_stack_adopt':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/enable_stack_adopt',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'DEFAULT/engine_life_check_timeout':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/engine_life_check_timeout',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '2',
}

heat_config { 'DEFAULT/heat_metadata_server_url':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/heat_metadata_server_url',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'http://192.168.0.2:8000',
}

heat_config { 'DEFAULT/heat_stack_user_role':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/heat_stack_user_role',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'heat_stack_user',
}

heat_config { 'DEFAULT/heat_waitcondition_server_url':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/heat_waitcondition_server_url',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'http://192.168.0.2:8000/v1/waitcondition',
}

heat_config { 'DEFAULT/heat_watch_server_url':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/heat_watch_server_url',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'http://192.168.0.2:8003',
}

heat_config { 'DEFAULT/instance_connection_https_validate_certificates':
  before => ['Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]', 'Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/instance_connection_https_validate_certificates',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '1',
}

heat_config { 'DEFAULT/instance_connection_is_secure':
  before => ['Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]', 'Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/instance_connection_is_secure',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '0',
}

heat_config { 'DEFAULT/instance_user':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/instance_user',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '',
}

heat_config { 'DEFAULT/log_dir':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/log_dir',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '/var/log/heat',
}

heat_config { 'DEFAULT/max_json_body_size':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/max_json_body_size',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '10880000',
}

heat_config { 'DEFAULT/max_resources_per_stack':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/max_resources_per_stack',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '20000',
}

heat_config { 'DEFAULT/max_template_size':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/max_template_size',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '5440000',
}

heat_config { 'DEFAULT/notification_driver':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/notification_driver',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'heat.openstack.common.notifier.rpc_notifier',
}

heat_config { 'DEFAULT/region_name_for_services':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/region_name_for_services',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'RegionOne',
}

heat_config { 'DEFAULT/rpc_backend':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/rpc_backend',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'rabbit',
}

heat_config { 'DEFAULT/rpc_response_timeout':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/rpc_response_timeout',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '600',
}

heat_config { 'DEFAULT/stack_domain_admin':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/stack_domain_admin',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'heat_admin',
}

heat_config { 'DEFAULT/stack_domain_admin_password':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/stack_domain_admin_password',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  secret => 'true',
  value  => 'CxKs9UObDHZOgw20Gv3kwtGT',
}

heat_config { 'DEFAULT/stack_user_domain_name':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/stack_user_domain_name',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'heat',
}

heat_config { 'DEFAULT/syslog_log_facility':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/syslog_log_facility',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'LOG_LOCAL0',
}

heat_config { 'DEFAULT/trusts_delegated_roles':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/trusts_delegated_roles',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => [],
}

heat_config { 'DEFAULT/use_stderr':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/use_stderr',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'false',
}

heat_config { 'DEFAULT/use_syslog':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/use_syslog',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'true',
}

heat_config { 'DEFAULT/use_syslog_rfc_format':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'true',
}

heat_config { 'DEFAULT/verbose':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'DEFAULT/verbose',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'true',
}

heat_config { 'database/connection':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'database/connection',
  notify => ['Exec[heat-dbsync]', 'Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  secret => 'true',
  value  => 'mysql://heat:qugZa4RJl8iT0K7060f1buWM@192.168.0.2/heat?read_timeout=60',
}

heat_config { 'database/idle_timeout':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'database/idle_timeout',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '3600',
}

heat_config { 'ec2authtoken/auth_uri':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'ec2authtoken/auth_uri',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'http://192.168.0.2:5000/v2.0',
}

heat_config { 'heat_api/bind_host':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api/bind_host',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '192.168.0.3',
}

heat_config { 'heat_api/bind_port':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api/bind_port',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '8004',
}

heat_config { 'heat_api/cert_file':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api/cert_file',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'heat_api/key_file':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api/key_file',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'heat_api/workers':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api/workers',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '0',
}

heat_config { 'heat_api_cfn/bind_host':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cfn/bind_host',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '192.168.0.3',
}

heat_config { 'heat_api_cfn/bind_port':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cfn/bind_port',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '8000',
}

heat_config { 'heat_api_cfn/cert_file':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cfn/cert_file',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'heat_api_cfn/key_file':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cfn/key_file',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'heat_api_cfn/workers':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cfn/workers',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '0',
}

heat_config { 'heat_api_cloudwatch/bind_host':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cloudwatch/bind_host',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '192.168.0.3',
}

heat_config { 'heat_api_cloudwatch/bind_port':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cloudwatch/bind_port',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '8003',
}

heat_config { 'heat_api_cloudwatch/cert_file':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cloudwatch/cert_file',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'heat_api_cloudwatch/key_file':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cloudwatch/key_file',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'heat_api_cloudwatch/workers':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'heat_api_cloudwatch/workers',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '0',
}

heat_config { 'keystone_authtoken/admin_password':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'keystone_authtoken/admin_password',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  secret => 'true',
  value  => 'CxKs9UObDHZOgw20Gv3kwtGT',
}

heat_config { 'keystone_authtoken/admin_tenant_name':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'services',
}

heat_config { 'keystone_authtoken/admin_user':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'keystone_authtoken/admin_user',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'heat',
}

heat_config { 'keystone_authtoken/auth_host':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'keystone_authtoken/auth_host',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '192.168.0.2',
}

heat_config { 'keystone_authtoken/auth_port':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'keystone_authtoken/auth_port',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '35357',
}

heat_config { 'keystone_authtoken/auth_protocol':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'keystone_authtoken/auth_protocol',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'http',
}

heat_config { 'keystone_authtoken/auth_uri':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'keystone_authtoken/auth_uri',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'http://192.168.0.2:5000/v2.0',
}

heat_config { 'keystone_authtoken/identity_uri':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'keystone_authtoken/identity_uri',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'oslo_messaging_rabbit/heartbeat_rate':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '2',
}

heat_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '0',
}

heat_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'false',
}

heat_config { 'oslo_messaging_rabbit/rabbit_host':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/rabbit_host',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'oslo_messaging_rabbit/rabbit_hosts':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '192.168.0.3:5673',
}

heat_config { 'oslo_messaging_rabbit/rabbit_password':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  secret => 'true',
  value  => 'OLCrvt99FgutnBs63PeFJchF',
}

heat_config { 'oslo_messaging_rabbit/rabbit_port':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/rabbit_port',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

heat_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'false',
}

heat_config { 'oslo_messaging_rabbit/rabbit_userid':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => 'nova',
}

heat_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  value  => '/',
}

heat_config { 'paste_deploy/flavor':
  ensure => 'absent',
  before => ['Exec[heat-dbsync]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]', 'Exec[wait_for_heat_config]'],
  name   => 'paste_deploy/flavor',
  notify => ['Service[heat-engine]', 'Service[heat-api]', 'Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
}

keystone_domain { 'heat_domain':
  ensure  => 'present',
  enabled => 'true',
  name    => 'heat',
}

keystone_user { 'heat_domain_admin':
  ensure   => 'present',
  domain   => 'heat',
  email    => 'heat_admin@localhost',
  enabled  => 'true',
  name     => 'heat_admin',
  password => 'CxKs9UObDHZOgw20Gv3kwtGT',
}

keystone_user_role { 'heat_admin@::heat':
  name  => 'heat_admin@::heat',
  roles => 'admin',
}

pacemaker_wrappers::service { 'heat-engine':
  ensure             => 'present',
  complex_type       => 'clone',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'migration-threshold' => '3', 'resource-stickiness' => '1'},
  ms_metadata        => {'interleave' => 'true'},
  name               => 'heat-engine',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'monitor' => {'interval' => '20', 'timeout' => '30'}, 'start' => {'timeout' => '60'}, 'stop' => {'timeout' => '60'}},
  prefix             => 'true',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'heat-engine',
  use_handler        => 'true',
}

package { 'heat-api-cfn':
  ensure => 'present',
  before => ['Class[Heat::Policy]', 'Service[heat-api-cfn]', 'Exec[remove_heat-api-cfn_override]', 'Exec[remove_heat-api-cfn_override]'],
  name   => 'heat-api-cfn',
  notify => 'Exec[heat-dbsync]',
  tag    => ['openstack', 'heat-package'],
}

package { 'heat-api-cloudwatch':
  ensure => 'present',
  before => ['Class[Heat::Policy]', 'Service[heat-api-cloudwatch]', 'Exec[remove_heat-api-cloudwatch_override]', 'Exec[remove_heat-api-cloudwatch_override]'],
  name   => 'heat-api-cloudwatch',
  notify => 'Exec[heat-dbsync]',
  tag    => ['openstack', 'heat-package'],
}

package { 'heat-api':
  ensure => 'present',
  before => ['Class[Heat::Policy]', 'Service[heat-api]', 'Exec[remove_heat-api_override]', 'Exec[remove_heat-api_override]'],
  name   => 'heat-api',
  notify => 'Exec[heat-dbsync]',
  tag    => ['openstack', 'heat-package'],
}

package { 'heat-common':
  ensure => 'present',
  before => ['Service[heat-api-cfn]', 'Service[heat-api-cloudwatch]'],
  name   => 'heat-common',
  notify => 'Exec[heat-dbsync]',
  tag    => ['openstack', 'heat-package'],
}

package { 'heat-docker':
  ensure => 'installed',
  name   => 'heat-docker',
  notify => 'Service[heat-engine]',
}

package { 'heat-engine':
  ensure => 'present',
  before => ['Service[heat-engine]', 'Exec[remove_heat-engine_override]', 'Exec[remove_heat-engine_override]'],
  name   => 'heat-engine',
  notify => 'Exec[heat-dbsync]',
  tag    => ['openstack', 'heat-package'],
}

package { 'python-heatclient':
  ensure => 'present',
  name   => 'python-heatclient',
  tag    => 'openstack',
}

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

service { 'heat-api-cfn':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'heat-api-cfn',
  tag        => 'heat-service',
}

service { 'heat-api-cloudwatch':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'heat-api-cloudwatch',
  tag        => 'heat-service',
}

service { 'heat-api':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'heat-api',
  require    => ['Package[heat-common]', 'Package[heat-api]'],
  tag        => 'heat-service',
}

service { 'heat-engine':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'heat-engine',
  provider   => 'pacemaker',
  require    => ['File[/etc/heat/heat.conf]', 'Package[heat-common]', 'Package[heat-engine]'],
  tag        => 'heat-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'heat-api-cfn':
  before       => 'Service[heat-api-cfn]',
  name         => 'heat-api-cfn',
  package_name => 'heat-api-cfn',
  service_name => 'heat-api-cfn',
}

tweaks::ubuntu_service_override { 'heat-api-cloudwatch':
  before       => 'Service[heat-api-cloudwatch]',
  name         => 'heat-api-cloudwatch',
  package_name => 'heat-api-cloudwatch',
  service_name => 'heat-api-cloudwatch',
}

tweaks::ubuntu_service_override { 'heat-api':
  before       => 'Service[heat-api]',
  name         => 'heat-api',
  package_name => 'heat-api',
  service_name => 'heat-api',
}

tweaks::ubuntu_service_override { 'heat-engine':
  before       => 'Service[heat-engine]',
  name         => 'heat-engine',
  package_name => 'heat-engine',
  service_name => 'heat-engine',
}

user { 'heat':
  gid     => 'heat',
  groups  => 'heat',
  name    => 'heat',
  require => 'Package[heat-common]',
  system  => 'true',
}

