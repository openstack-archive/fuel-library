anchor { 'rabbitmq::begin':
  before => 'Class[Rabbitmq::Install]',
  name   => 'rabbitmq::begin',
}

anchor { 'rabbitmq::end':
  name => 'rabbitmq::end',
}

apt::setting { 'conf-update-stamp':
  ensure        => 'file',
  content       => '// This file is managed by Puppet. DO NOT EDIT.
APT::Update::Post-Invoke-Success {"touch /var/lib/apt/periodic/update-success-stamp 2>/dev/null || true";};
',
  name          => 'conf-update-stamp',
  notify_update => 'true',
  priority      => '15',
}

apt::setting { 'list-rabbitmq':
  ensure        => 'absent',
  content       => '# This file is managed by Puppet. DO NOT EDIT.
# rabbitmq
deb http://www.rabbitmq.com/debian/ testing main
',
  name          => 'list-rabbitmq',
  notify_update => 'true',
  priority      => '50',
}

apt::source { 'rabbitmq':
  ensure         => 'absent',
  allow_unsigned => 'false',
  comment        => 'rabbitmq',
  include        => {},
  include_src    => 'false',
  key            => 'F7B8CEA6056E8E56',
  key_source     => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
  location       => 'http://www.rabbitmq.com/debian/',
  name           => 'rabbitmq',
  release        => 'testing',
  repos          => 'main',
}

class { 'Apt::Params':
  name => 'Apt::Params',
}

class { 'Apt::Update':
  name => 'Apt::Update',
}

class { 'Apt':
  keys     => {},
  name     => 'Apt',
  pins     => {},
  ppas     => {},
  proxy    => {},
  purge    => {},
  settings => {},
  sources  => {},
  update   => {},
}

class { 'Cluster::Rabbitmq_fence':
  enabled => 'true',
  name    => 'Cluster::Rabbitmq_fence',
  require => 'Class[Rabbitmq]',
}

class { 'Nova::Rabbitmq':
  cluster_disk_nodes => 'false',
  enabled            => 'true',
  name               => 'Nova::Rabbitmq',
  password           => '1GXPbTgb',
  port               => '5672',
  rabbitmq_class     => 'false',
  require            => 'Class[Rabbitmq]',
  userid             => 'nova',
  virtual_host       => '/',
}

class { 'Pacemaker_wrappers::Rabbitmq':
  admin_pass      => '1GXPbTgb',
  admin_user      => 'nova',
  before          => 'Class[Nova::Rabbitmq]',
  command_timeout => ''--signal=KILL'',
  debug           => 'false',
  erlang_cookie   => 'EOKOWXQREETZSHFNTPEY',
  name            => 'Pacemaker_wrappers::Rabbitmq',
  ocf_script_file => 'cluster/ocf/rabbitmq',
  port            => '5673',
  primitive_type  => 'rabbitmq-server',
  service_name    => 'rabbitmq-server',
}

class { 'Rabbitmq::Config':
  name   => 'Rabbitmq::Config',
  notify => 'Class[Rabbitmq::Service]',
}

class { 'Rabbitmq::Install::Rabbitmqadmin':
  name => 'Rabbitmq::Install::Rabbitmqadmin',
}

class { 'Rabbitmq::Install':
  before => ['Class[Rabbitmq::Config]', 'Exec[epmd_daemon]'],
  name   => 'Rabbitmq::Install',
}

class { 'Rabbitmq::Management':
  before => 'Anchor[rabbitmq::end]',
  name   => 'Rabbitmq::Management',
}

class { 'Rabbitmq::Params':
  name => 'Rabbitmq::Params',
}

class { 'Rabbitmq::Repo::Apt':
  before      => 'Package[rabbitmq-server]',
  include_src => 'false',
  key         => 'F7B8CEA6056E8E56',
  key_source  => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
  location    => 'http://www.rabbitmq.com/debian/',
  name        => 'Rabbitmq::Repo::Apt',
  release     => 'testing',
  repos       => 'main',
}

class { 'Rabbitmq::Service':
  before         => ['Class[Rabbitmq::Install::Rabbitmqadmin]', 'Class[Rabbitmq::Management]'],
  name           => 'Rabbitmq::Service',
  service_ensure => 'running',
  service_manage => 'true',
  service_name   => 'rabbitmq-server',
}

class { 'Rabbitmq':
  admin_enable               => 'true',
  cluster_node_type          => 'disc',
  cluster_nodes              => [],
  cluster_partition_handling => 'ignore',
  config                     => 'rabbitmq/rabbitmq.config.erb',
  config_cluster             => 'false',
  config_kernel_variables    => {'inet_default_connect_options' => '[{nodelay,true}]', 'inet_dist_listen_max' => '41055', 'inet_dist_listen_min' => '41055', 'net_ticktime' => '10'},
  config_path                => '/etc/rabbitmq/rabbitmq.config',
  config_stomp               => 'false',
  config_variables           => {'cluster_partition_handling' => 'autoheal', 'default_permissions' => '[<<".*">>, <<".*">>, <<".*">>]', 'default_vhost' => '<<"/">>', 'log_levels' => '[{connection,info}]', 'mnesia_table_loading_timeout' => '10000', 'tcp_listen_options' => '[
      binary,
      {packet, raw},
      {reuseaddr, true},
      {backlog, 128},
      {nodelay, true},
      {exit_on_close, false},
      {keepalive, true}
    ]'},
  default_pass               => '1GXPbTgb',
  default_user               => 'nova',
  delete_guest_user          => 'true',
  env_config                 => 'rabbitmq/rabbitmq-env.conf.erb',
  env_config_path            => '/etc/rabbitmq/rabbitmq-env.conf',
  environment_variables      => {'PID_FILE' => '/var/run/rabbitmq/p_pid', 'SERVER_ERL_ARGS' => '"+K true +A48 +P 1048576"'},
  ldap_auth                  => 'false',
  ldap_log                   => 'false',
  ldap_port                  => '389',
  ldap_server                => 'ldap',
  ldap_use_ssl               => 'false',
  ldap_user_dn_pattern       => 'cn=username,ou=People,dc=example,dc=com',
  management_port            => '15672',
  name                       => 'Rabbitmq',
  node_ip_address            => '192.168.0.3',
  package_apt_pin            => '',
  package_ensure             => 'installed',
  package_gpg_key            => 'http://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
  package_name               => 'rabbitmq-server',
  package_provider           => 'apt',
  plugin_dir                 => '/usr/lib/rabbitmq/lib/rabbitmq_server-3.1.5/plugins',
  port                       => '5673',
  repos_ensure               => 'false',
  service_ensure             => 'running',
  service_manage             => 'true',
  service_name               => 'rabbitmq-server',
  ssl                        => 'false',
  ssl_cacert                 => 'UNSET',
  ssl_cert                   => 'UNSET',
  ssl_fail_if_no_peer_cert   => 'false',
  ssl_key                    => 'UNSET',
  ssl_management_port        => '15671',
  ssl_only                   => 'false',
  ssl_port                   => '5671',
  ssl_stomp_port             => '6164',
  ssl_verify                 => 'verify_none',
  stomp_ensure               => 'false',
  stomp_port                 => '6163',
  tcp_keepalive              => 'false',
  version                    => '3.3.5',
  wipe_db_on_cookie_change   => 'false',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Staging::Params':
  name => 'Staging::Params',
}

class { 'Staging':
  exec_path => '/usr/local/bin:/usr/bin:/bin',
  group     => '0',
  mode      => '0755',
  name      => 'Staging',
  owner     => '0',
  path      => '/opt/staging',
}

class { 'main':
  name => 'main',
}

cs_resource { 'p_rabbitmq-server':
  ensure          => 'present',
  before          => 'Service[rabbitmq-server]',
  complex_type    => 'master',
  metadata        => {'failure-timeout' => '30s', 'migration-threshold' => '10', 'resource-stickiness' => '100'},
  ms_metadata     => {'interleave' => 'true', 'master-max' => '1', 'master-node-max' => '1', 'notify' => 'true', 'ordered' => 'false', 'target-role' => 'Master'},
  name            => 'p_rabbitmq-server',
  operations      => {'demote' => {'timeout' => '120'}, 'monitor' => {'interval' => '30', 'timeout' => '180'}, 'monitor:Master' => {'interval' => '27', 'role' => 'Master', 'timeout' => '180'}, 'monitor:Slave' => {'OCF_CHECK_LEVEL' => '30', 'interval' => '103', 'role' => 'Slave', 'timeout' => '180'}, 'notify' => {'timeout' => '180'}, 'promote' => {'timeout' => '120'}, 'start' => {'timeout' => '360'}, 'stop' => {'timeout' => '120'}},
  parameters      => {'admin_password' => '1GXPbTgb', 'admin_user' => 'nova', 'command_timeout' => ''--signal=KILL'', 'debug' => 'false', 'erlang_cookie' => 'EOKOWXQREETZSHFNTPEY', 'node_port' => '5673'},
  primitive_class => 'ocf',
  primitive_type  => 'rabbitmq-server',
  provided_by     => 'fuel',
}

exec { '/var/lib/rabbitmq/rabbitmqadmin':
  command   => 'curl -k --noproxy localhost --retry 30 --retry-delay 6 -f -L -o /var/lib/rabbitmq/rabbitmqadmin http://nova:1GXPbTgb@localhost:15672/cli/rabbitmqadmin',
  creates   => '/var/lib/rabbitmq/rabbitmqadmin',
  cwd       => '/var/lib/rabbitmq',
  logoutput => 'on_failure',
  path      => '/usr/local/bin:/usr/bin:/bin',
  timeout   => '180',
  tries     => '30',
  try_sleep => '6',
}

exec { 'apt_update':
  command     => '/usr/bin/apt-get update',
  logoutput   => 'on_failure',
  refreshonly => 'true',
  try_sleep   => '1',
}

exec { 'enable_corosync_notifyd':
  before  => 'Service[corosync-notifyd]',
  command => 'sed -i s/START=no/START=yes/ /etc/default/corosync-notifyd',
  path    => ['/bin', '/usr/bin'],
  unless  => 'grep START=yes /etc/default/corosync-notifyd',
}

exec { 'epmd_daemon':
  before  => 'Rabbitmq_plugin[rabbitmq_management]',
  command => 'epmd -daemon',
  group   => 'rabbitmq',
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  unless  => 'pgrep epmd',
  user    => 'rabbitmq',
}

exec { 'fix_corosync_notifyd_init_args':
  before  => 'Service[corosync-notifyd]',
  command => 'sed -i s/DAEMON_ARGS=\"\"/DAEMON_ARGS=\"-d\"/ /etc/init.d/corosync-notifyd',
  onlyif  => 'grep 'DAEMON_ARGS=""' /etc/init.d/corosync-notifyd',
  path    => ['/bin', '/usr/bin'],
}

exec { 'fix_corosync_notifyd_init_pidfile':
  before  => 'Service[corosync-notifyd]',
  command => 'sed -i '/PIDFILE=\/var\/run\/corosync.pid/d' /etc/init.d/corosync-notifyd',
  onlyif  => 'grep 'PIDFILE=/var/run/corosync.pid' /etc/init.d/corosync-notifyd',
  path    => ['/bin', '/usr/bin'],
}

exec { 'remove_rabbitmq-server_override':
  before  => ['Service[rabbitmq-server]', 'Service[rabbitmq-server]'],
  command => 'rm -f /etc/init/rabbitmq-server.override',
  onlyif  => 'test -f /etc/init/rabbitmq-server.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/apt/apt.conf.d/15update-stamp':
  ensure  => 'file',
  content => '// This file is managed by Puppet. DO NOT EDIT.
APT::Update::Post-Invoke-Success {"touch /var/lib/apt/periodic/update-success-stamp 2>/dev/null || true";};
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apt::Update]',
  owner   => 'root',
  path    => '/etc/apt/apt.conf.d/15update-stamp',
}

file { '/etc/apt/sources.list.d/rabbitmq.list':
  ensure  => 'absent',
  content => '# This file is managed by Puppet. DO NOT EDIT.
# rabbitmq
deb http://www.rabbitmq.com/debian/ testing main
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apt::Update]',
  owner   => 'root',
  path    => '/etc/apt/sources.list.d/rabbitmq.list',
}

file { '/etc/rabbitmq/ssl':
  ensure => 'directory',
  group  => '0',
  mode   => '0644',
  owner  => '0',
  path   => '/etc/rabbitmq/ssl',
}

file { '/etc/rabbitmq':
  ensure => 'directory',
  group  => '0',
  mode   => '0644',
  owner  => '0',
  path   => '/etc/rabbitmq',
}

file { '/opt/staging':
  ensure => 'directory',
  group  => '0',
  mode   => '0755',
  owner  => '0',
  path   => '/opt/staging',
}

file { '/usr/local/bin/rabbitmqadmin':
  group   => 'root',
  mode    => '0755',
  owner   => 'root',
  path    => '/usr/local/bin/rabbitmqadmin',
  require => 'Staging::File[rabbitmqadmin]',
  source  => '/var/lib/rabbitmq/rabbitmqadmin',
}

file { 'create_rabbitmq-server_override':
  ensure  => 'present',
  before  => ['Package[rabbitmq-server]', 'Package[rabbitmq-server]', 'Exec[remove_rabbitmq-server_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/rabbitmq-server.override',
}

file { 'ocf_handler_rabbitmq-server':
  ensure  => 'present',
  before  => 'Service[rabbitmq-server]',
  content => '#!/bin/bash
export PATH='/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
export OCF_ROOT='/usr/lib/ocf'
export OCF_RA_VERSION_MAJOR='1'
export OCF_RA_VERSION_MINOR='0'
export OCF_RESOURCE_INSTANCE='p_rabbitmq-server'

# OCF Parameters
                                    export OCF_RESKEY_node_port='5673'
                                    export OCF_RESKEY_debug='false'
                                    export OCF_RESKEY_command_timeout='--signal=KILL'
                                    export OCF_RESKEY_erlang_cookie='EOKOWXQREETZSHFNTPEY'
                                    export OCF_RESKEY_admin_user='nova'
                                    export OCF_RESKEY_admin_password='1GXPbTgb'
    
help() {
cat<<EOF
OCF wrapper for rabbitmq-server Pacemaker primitive

Usage: ocf_handler_rabbitmq-server [-dh] (action)

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
  bash -x /usr/lib/ocf/resource.d/fuel/rabbitmq-server "${ACTION}"
else
  /usr/lib/ocf/resource.d/fuel/rabbitmq-server "${ACTION}"
fi
ec="${?}"

message="$(ec2error ${ec})"
echo "Exit status: ${message} (${ec})"
exit "${ec}"
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/usr/local/bin/ocf_handler_rabbitmq-server',
}

file { 'preferences.d':
  ensure  => 'directory',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apt::Update]',
  owner   => 'root',
  path    => '/etc/apt/preferences.d',
  purge   => 'false',
  recurse => 'false',
}

file { 'preferences':
  ensure => 'file',
  group  => 'root',
  mode   => '0644',
  notify => 'Class[Apt::Update]',
  owner  => 'root',
  path   => '/etc/apt/preferences',
}

file { 'rabbitmq-env.config':
  ensure  => 'file',
  content => 'NODE_IP_ADDRESS=192.168.0.3
NODE_PORT=5673
PID_FILE=/var/run/rabbitmq/p_pid
SERVER_ERL_ARGS="+K true +A48 +P 1048576"
',
  group   => '0',
  mode    => '0644',
  notify  => 'Class[Rabbitmq::Service]',
  owner   => '0',
  path    => '/etc/rabbitmq/rabbitmq-env.conf',
}

file { 'rabbitmq.config':
  ensure  => 'file',
  content => '% This file managed by Puppet
% Template Path: rabbitmq/templates/rabbitmq.config
[
  {rabbit, [
    {cluster_partition_handling, autoheal},
    {default_permissions, [<<".*">>, <<".*">>, <<".*">>]},
    {default_vhost, <<"/">>},
    {log_levels, [{connection,info}]},
    {mnesia_table_loading_timeout, 10000},
    {tcp_listen_options, [
      binary,
      {packet, raw},
      {reuseaddr, true},
      {backlog, 128},
      {nodelay, true},
      {exit_on_close, false},
      {keepalive, true}
    ]},
    {default_user, <<"nova">>},
    {default_pass, <<"1GXPbTgb">>}
  ]},
  {kernel, [
    {inet_default_connect_options, [{nodelay,true}]},
    {inet_dist_listen_max, 41055},
    {inet_dist_listen_min, 41055},
    {net_ticktime, 10}
  ]}
,
  {rabbitmq_management, [
    {listener, [
      {port, 15672}
    ]}
  ]}
].
% EOF
',
  group   => '0',
  mode    => '0644',
  notify  => 'Class[Rabbitmq::Service]',
  owner   => '0',
  path    => '/etc/rabbitmq/rabbitmq.config',
}

file { 'rabbitmqadmin.conf':
  ensure  => 'file',
  content => '[default]
ssl = False
port = 15672
',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/rabbitmq/rabbitmqadmin.conf',
  require => 'File[/etc/rabbitmq]',
}

file { 'sources.list.d':
  ensure  => 'directory',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apt::Update]',
  owner   => 'root',
  path    => '/etc/apt/sources.list.d',
  purge   => 'false',
  recurse => 'false',
}

file { 'sources.list':
  ensure => 'file',
  group  => 'root',
  mode   => '0644',
  notify => 'Class[Apt::Update]',
  owner  => 'root',
  path   => '/etc/apt/sources.list',
}

pacemaker_wrappers::service { 'rabbitmq-server':
  ensure             => 'present',
  complex_type       => 'master',
  create_primitive   => 'true',
  handler_root_path  => '/usr/local/bin',
  metadata           => {'failure-timeout' => '30s', 'migration-threshold' => '10', 'resource-stickiness' => '100'},
  ms_metadata        => {'interleave' => 'true', 'master-max' => '1', 'master-node-max' => '1', 'notify' => 'true', 'ordered' => 'false', 'target-role' => 'Master'},
  name               => 'rabbitmq-server',
  ocf_root_path      => '/usr/lib/ocf',
  operations         => {'demote' => {'timeout' => '120'}, 'monitor' => {'interval' => '30', 'timeout' => '180'}, 'monitor:Master' => {'interval' => '27', 'role' => 'Master', 'timeout' => '180'}, 'monitor:Slave' => {'OCF_CHECK_LEVEL' => '30', 'interval' => '103', 'role' => 'Slave', 'timeout' => '180'}, 'notify' => {'timeout' => '180'}, 'promote' => {'timeout' => '120'}, 'start' => {'timeout' => '360'}, 'stop' => {'timeout' => '120'}},
  parameters         => {'admin_password' => '1GXPbTgb', 'admin_user' => 'nova', 'command_timeout' => ''--signal=KILL'', 'debug' => 'false', 'erlang_cookie' => 'EOKOWXQREETZSHFNTPEY', 'node_port' => '5673'},
  prefix             => 'true',
  primitive_class    => 'ocf',
  primitive_provider => 'fuel',
  primitive_type     => 'rabbitmq-server',
  use_handler        => 'true',
}

package { 'fuel-rabbit-fence':
  before => 'Service[rabbit-fence]',
  name   => 'fuel-rabbit-fence',
}

package { 'python-daemon':
  before => 'Service[dbus]',
  name   => 'python-daemon',
}

package { 'python-dbus':
  before => 'Service[dbus]',
  name   => 'python-dbus',
}

package { 'python-gobject-2':
  before => 'Service[dbus]',
  name   => 'python-gobject-2',
}

package { 'python-gobject':
  before => 'Service[dbus]',
  name   => 'python-gobject',
}

package { 'rabbitmq-server':
  ensure   => 'installed',
  before   => ['Exec[remove_rabbitmq-server_override]', 'Exec[remove_rabbitmq-server_override]'],
  name     => 'rabbitmq-server',
  notify   => 'Class[Rabbitmq::Service]',
  provider => 'apt',
}

rabbitmq_plugin { 'rabbitmq_management':
  ensure   => 'present',
  name     => 'rabbitmq_management',
  notify   => 'Class[Rabbitmq::Service]',
  provider => 'rabbitmqplugins',
  require  => 'Class[Rabbitmq::Install]',
}

rabbitmq_user { 'guest':
  ensure   => 'absent',
  name     => 'guest',
  provider => 'rabbitmqctl',
}

rabbitmq_user { 'nova':
  admin    => 'true',
  name     => 'nova',
  password => '1GXPbTgb',
  provider => 'rabbitmqctl',
}

rabbitmq_user_permissions { 'nova@/':
  configure_permission => '.*',
  name                 => 'nova@/',
  provider             => 'rabbitmqctl',
  read_permission      => '.*',
  write_permission     => '.*',
}

rabbitmq_vhost { '/':
  name     => '/',
  provider => 'rabbitmqctl',
}

service { 'corosync-notifyd':
  ensure     => 'running',
  before     => 'Package[fuel-rabbit-fence]',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'corosync-notifyd',
}

service { 'dbus':
  ensure     => 'running',
  before     => 'Service[corosync-notifyd]',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'dbus',
}

service { 'rabbit-fence':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'fuel-rabbit-fence',
  require    => 'Package[rabbitmq-server]',
}

service { 'rabbitmq-server':
  ensure     => 'running',
  before     => ['Rabbitmq_user[guest]', 'Rabbitmq_user[nova]'],
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'rabbitmq-server',
  provider   => 'pacemaker',
}

stage { 'main':
  name => 'main',
}

staging::file { 'rabbitmqadmin':
  curl_option => '-k --noproxy localhost --retry 30 --retry-delay 6',
  name        => 'rabbitmqadmin',
  require     => ['Class[Rabbitmq::Service]', 'Rabbitmq_plugin[rabbitmq_management]'],
  source      => 'http://nova:1GXPbTgb@localhost:15672/cli/rabbitmqadmin',
  subdir      => 'rabbitmq',
  target      => '/var/lib/rabbitmq/rabbitmqadmin',
  timeout     => '180',
  tries       => '30',
  try_sleep   => '6',
  wget_option => '--no-proxy',
}

tweaks::ubuntu_service_override { 'rabbitmq-server':
  name         => 'rabbitmq-server',
  package_name => 'rabbitmq-server',
  service_name => 'rabbitmq-server',
}

