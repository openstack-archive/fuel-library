class { 'Murano::Api':
  enabled        => 'true',
  host           => '192.168.0.3',
  manage_service => 'true',
  name           => 'Murano::Api',
  package_ensure => 'present',
  port           => '8082',
}

class { 'Murano::Client':
  name           => 'Murano::Client',
  package_ensure => 'present',
}

class { 'Murano::Dashboard':
  api_url               => 'http://192.168.0.3:8082',
  collect_static_script => '/usr/share/openstack-dashboard/manage.py',
  max_file_size         => '5',
  metadata_dir          => '/var/cache/muranodashboard-cache',
  modify_config         => '/usr/bin/modify-horizon-config.sh',
  name                  => 'Murano::Dashboard',
  package_ensure        => 'present',
  repo_url              => 'http://catalog.openstack.org/',
  settings_py           => '/usr/share/openstack-dashboard/openstack_dashboard/settings.py',
}

class { 'Murano::Engine':
  enabled        => 'true',
  manage_service => 'true',
  name           => 'Murano::Engine',
  package_ensure => 'present',
}

class { 'Murano::Params':
  name => 'Murano::Params',
}

class { 'Murano::Policy':
  before      => ['Service[murano-api]', 'Service[murano-engine]'],
  name        => 'Murano::Policy',
  policies    => {},
  policy_path => '/etc/murano/policy.json',
}

class { 'Murano::Rabbitmq':
  firewall_rule_name  => '203 murano-rabbitmq',
  name                => 'Murano::Rabbitmq',
  rabbit_cluster_port => '41056',
  rabbit_config_path  => '/etc/rabbitmq/rabbitmq-murano.config',
  rabbit_node_name    => 'murano@localhost',
  rabbit_password     => 'Nmn2wr9S',
  rabbit_port         => '55572',
  rabbit_user         => 'murano',
  rabbit_vhost        => '/',
}

class { 'Murano':
  data_dir             => '/var/cache/murano',
  database_connection  => 'mysql://murano:R3SuvZbh@192.168.0.2/murano?read_timeout=60',
  debug                => 'false',
  default_router       => 'murano-default-router',
  external_network     => 'net04_ext',
  identity_uri         => 'http://192.168.0.2:35357/',
  keystone_password    => 'xP8WtHQw',
  keystone_region      => 'RegionOne',
  keystone_signing_dir => '/tmp/keystone-signing-muranoapi',
  keystone_tenant      => 'services',
  keystone_uri         => 'https://public.fuel.local:5000/v2.0/',
  keystone_username    => 'murano',
  log_dir              => '/var/log/murano',
  log_facility         => 'LOG_LOCAL0',
  name                 => 'Murano',
  notification_driver  => 'messagingv2',
  package_ensure       => 'present',
  rabbit_ha_queues     => 'true',
  rabbit_os_hosts      => ['192.168.0.3:5673', ' 192.168.0.2:5673', ' 192.168.0.4:5673'],
  rabbit_os_password   => 'c7fQJeSe',
  rabbit_os_port       => '5673',
  rabbit_os_user       => 'nova',
  rabbit_own_host      => '10.109.1.2',
  rabbit_own_password  => 'Nmn2wr9S',
  rabbit_own_port      => '55572',
  rabbit_own_user      => 'murano',
  require              => ['Class[Mysql::Bindings]', 'Class[Mysql::Bindings::Python]'],
  service_host         => '192.168.0.3',
  service_port         => '8082',
  use_neutron          => 'true',
  use_stderr           => 'false',
  use_syslog           => 'true',
  verbose              => 'true',
}

class { 'Mysql::Bindings::Python':
  name => 'Mysql::Bindings::Python',
}

class { 'Mysql::Bindings':
  name => 'Mysql::Bindings',
}

class { 'Mysql::Params':
  name => 'Mysql::Params',
}

class { 'Mysql::Python':
  name           => 'Mysql::Python',
  package_ensure => 'present',
  package_name   => 'python-mysqldb',
}

class { 'Openstack::Firewall':
  name => 'Openstack::Firewall',
}

class { 'Rabbitmq::Params':
  name => 'Rabbitmq::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'clean_horizon_config':
  command => '/usr/bin/modify-horizon-config.sh uninstall',
  onlyif  => ['test -f /usr/bin/modify-horizon-config.sh', 'grep MURANO_CONFIG_SECTION_BEGIN /usr/share/openstack-dashboard/openstack_dashboard/settings.py'],
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
}

exec { 'create_murano_user':
  before  => 'Exec[create_murano_vhost]',
  command => 'rabbitmqctl -n 'murano@localhost' add_user 'murano' 'Nmn2wr9S'',
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  unless  => 'rabbitmqctl -n 'murano@localhost' list_users | grep -qE '^murano\s*\['',
}

exec { 'create_murano_vhost':
  before  => 'Exec[set_murano_user_permissions]',
  command => 'rabbitmqctl -n 'murano@localhost' add_vhost '/'',
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  unless  => 'rabbitmqctl -n 'murano@localhost' list_vhosts | grep -qE '^/$'',
}

exec { 'django_collectstatic':
  command     => '/usr/share/openstack-dashboard/manage.py collectstatic --noinput',
  environment => ['APACHE_USER=horizon', 'APACHE_GROUP=horizon'],
  refreshonly => 'true',
}

exec { 'install_init_script':
  before  => 'Service[rabbitmq-server-murano]',
  command => 'update-rc.d 'rabbit-server-murano' defaults',
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  unless  => 'test -f /etc/init.d/rabbit-server-murano',
}

exec { 'murano-dbmanage':
  before      => ['Service[murano-api]', 'Service[murano-engine]'],
  command     => 'murano-db-manage --config-file /etc/murano/murano.conf upgrade',
  logoutput   => 'on_failure',
  path        => '/usr/bin',
  refreshonly => 'true',
  subscribe   => ['Package[murano-common]', 'Murano_config[database/connection]'],
  user        => 'murano',
}

exec { 'remove_murano-api_override':
  before  => ['Service[murano-api]', 'Service[murano-api]'],
  command => 'rm -f /etc/init/murano-api.override',
  onlyif  => 'test -f /etc/init/murano-api.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_murano-engine_override':
  before  => ['Service[murano-engine]', 'Service[murano-engine]'],
  command => 'rm -f /etc/init/murano-engine.override',
  onlyif  => 'test -f /etc/init/murano-engine.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'remove_murano_guest':
  before  => 'Exec[create_murano_user]',
  command => 'rabbitmqctl -n 'murano@localhost' delete_user guest',
  onlyif  => 'rabbitmqctl -n 'murano@localhost' list_users | grep -qE '^guest\s*\['',
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
}

exec { 'set_murano_user_permissions':
  command => 'rabbitmqctl -n 'murano@localhost' set_permissions -p '/' 'murano' '.*' '.*' '.*'',
  path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
}

file { 'create_murano-api_override':
  ensure  => 'present',
  before  => 'Exec[remove_murano-api_override]',
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/murano-api.override',
}

file { 'create_murano-engine_override':
  ensure  => 'present',
  before  => 'Exec[remove_murano-engine_override]',
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/murano-engine.override',
}

file { 'init_script':
  before  => 'Exec[install_init_script]',
  content => '#!/bin/sh
#
# rabbitmq-server Murano RabbitMQ broker
#
# chkconfig: - 80 05
# description: Enable AMQP service provided by RabbitMQ
#

### BEGIN INIT INFO
# Provides:      rabbitmq-server
# Required-Start:  $remote_fs $network
# Required-Stop:   $remote_fs $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description:     RabbitMQ broker
# Short-Description: Enable AMQP service provided by RabbitMQ broker for Murano
### END INIT INFO

PATH="/sbin:/usr/sbin:/bin:/usr/bin"
NAME="rabbitmq-server-murano"
DAEMON="/usr/sbin/rabbitmq-server"
CONTROL="/usr/sbin/rabbitmqctl"
DESC="Murano RabbitMQ Server"
USER="rabbitmq"
ROTATE_SUFFIX=".old"

export RABBITMQ_LOG_DIR="/var/log/rabbitmq"
export RABBITMQ_PID_FILE="/var/run/rabbitmq-murano/pid"
export RABBITMQ_CONFIG_FILE="/etc/rabbitmq/rabbitmq-murano"
export RABBITMQ_MNESIA_BASE="/var/lib/rabbitmq/mnesia-murano"
export RABBITMQ_LOG_BASE="/var/log/rabbitmq-murano"
export RABBITMQ_ENABLED_PLUGINS_FILE="/etc/rabbitmq/enabled_plugins_murano"
export RABBITMQ_NODENAME="murano@localhost"
export RABBITMQ_NODE_PORT="55572"
export RABBITMQ_NODE_IP_ADDRESS="0.0.0.0"

LOCK_DIR="/var/lock/rabbitmq"
LOCK_FILE="${LOCK_DIR}/${NAME}"
mkdir -p "${LOCK_DIR}"
chown -R "${USER}:${USER}" "${LOCK_DIR}"

test -x "${DAEMON}" || exit 0
test -x "${CONTROL}" || exit 0

CONTROL="${CONTROL} -n ${RABBITMQ_NODENAME}"

RETVAL="0"

[ -f /etc/default/${NAME} ] && . /etc/default/${NAME}

check_dir () {
    mkdir -p "${1}"
    chown -R "${USER}:${USER}" "${1}"
    chmod "755" "${1}"
}

ensure_dirs () {
    PID_DIR=`dirname ${RABBITMQ_PID_FILE}`
    check_dir "${PID_DIR}"
    check_dir "${RABBITMQ_LOG_DIR}"
    check_dir "${RABBITMQ_LOG_BASE}"
    check_dir "${RABBITMQ_MNESIA_BASE}"
}

remove_pid () {
    rm -f "${RABBITMQ_PID_FILE}"
}
#####

c_start_rabbitmq () {
    status_rabbitmq quiet
    if [ $RETVAL != 0 ] ; then
    #Slave nodes fail to start until master is not up and running
    #So, give slaves several attempts to start
    #Rabbit database will be moved out before last attempt.
        local MAX_START_ATTEMPTS=3
        printf '%s\n' "RabbitMQ is going to make ${MAX_START_ATTEMPTS} \
 attempts to find master node and start."
        while test $MAX_START_ATTEMPTS -ne 0
        do
            RETVAL=0
            ensure_pid_dir
            printf '%s\n' "${MAX_START_ATTEMPTS} attempts left to start \
 RabbitMQ Server before consider start failed."
            if [ $MAX_START_ATTEMPTS = 1 ] ; then
                move_out_rabbit_database_to_backup
            fi
            set +e
            RABBITMQ_PID_FILE=$PID_FILE start-stop-daemon --quiet \
                --chuid rabbitmq --start --exec $DAEMON \
                --pidfile "$RABBITMQ_PID_FILE" --background
            $CONTROL wait $PID_FILE >/dev/null 2>&1
            RETVAL=$?
            set -e
            if [ $RETVAL != 0 ] ; then
                remove_pid
            else
                if [ $MAX_START_ATTEMPTS = 1 ] ; then
                    set_nova_rabbit_credentials
                    RETVAL=0
                fi
                break
            fi
            MAX_START_ATTEMPTS=$((MAX_START_ATTEMPTS - 1))
        done
    else
        RETVAL=3
    fi
}
#####

start_rabbitmq () {
    status_rabbitmq quiet

    if [ "${RETVAL}" = "0" ] ; then
        echo "Murano RabbitMQ is currently running!"
        RETVAL="0"
        return
    fi

    ensure_dirs
    start-stop-daemon --quiet --chuid rabbitmq \
        --start --exec "${DAEMON}" \
        --pidfile "${RABBITMQ_PID_FILE}" --background
    ${CONTROL} wait "${RABBITMQ_PID_FILE}" 1> "/dev/null" 2>&1
    RETVAL="${?}"

    if [ "${RETVAL}" -gt "0" ]; then
        remove_pid
        echo "Murano RabbitMQ start FAILED!"
        RETVAL="1"
    else
        echo "Murano RabbitMQ start SUCCESS!"
        if [ -n "${LOCK_FILE}" ]; then
            touch "${LOCK_FILE}"
        fi
        RETVAL="0"
    fi
}

stop_rabbitmq () {
    status_rabbitmq quiet

    if [ "${RETVAL}" != 0 ]; then
        echo "RabbitMQ is not running!"
        RETVAL="0"
        return
    fi

    ${CONTROL} stop "${RABBITMQ_PID_FILE}" > "${RABBITMQ_LOG_BASE}/shutdown_log" 2> "${RABBITMQ_LOG_BASE}/shutdown_err"
    RETVAL="${?}"

    if [ "${RETVAL}" = "0" ] ; then
        remove_pid
        echo "Murano RabbitMQ stop SUCCESS!"
        if [ -n "{$LOCK_FILE}" ] ; then
            rm -f "${LOCK_FILE}"
        fi
        RETVAL="0"
    else
        echo "Murano RabbitMQ stop FAILED!"
        RETVAL="1"
    fi
}

status_rabbitmq () {
    if [ "${1}" != "quiet" ] ; then
        ${CONTROL} status 2>&1
    else
        ${CONTROL} status > /dev/null 2>&1
    fi

    if [ "${?}" != "0" ]; then
        RETVAL="3"
    fi
}

rotate_logs_rabbitmq () {
    ${CONTROL} rotate_logs "${ROTATE_SUFFIX}"
    if [ $? != 0 ]; then
        RETVAL="1"
    fi
}

restart_running_rabbitmq () {
    status_rabbitmq quiet

    if [ "${RETVAL}" != "0" ]; then
        echo "RabbitMQ is not runnning!"
        exit 0
    fi

    restart_rabbitmq
}

restart_rabbitmq () {
    stop_rabbitmq
    start_rabbitmq
}

case "${1}" in
    start)
        echo "Starting $DESC"
        start_rabbitmq
    ;;
    stop)
        echo "Stopping $DESC"
        stop_rabbitmq
    ;;
    status)
        status_rabbitmq
    ;;
    rotate-logs)
        echo "Rotating log files for $DESC"
        rotate_logs_rabbitmq
    ;;
    force-reload|reload|restart)
        echo "Restarting $DESC"
        restart_rabbitmq
    ;;
    try-restart)
        echo "Restarting $DESC"
        restart_running_rabbitmq
    ;;
    *)
    echo "Usage: $0 {start|stop|status|rotate-logs|restart|condrestart|try-restart|reload|force-reload}" >&2
        exit 1
    ;;
esac

exit "${RETVAL}"
',
  group   => 'root',
  mode    => '0755',
  notify  => 'Service[rabbitmq-server-murano]',
  owner   => 'root',
  path    => '/etc/init.d/rabbit-server-murano',
}

file { 'rabbitmq_config':
  before  => 'File[init_script]',
  content => '[
{rabbit, [{tcp_listeners, [55572]}]},
{kernel,[
  {inet_dist_listen_min, 41056},
  {inet_dist_listen_max, 41056}
]}
].',
  group   => 'root',
  mode    => '0644',
  notify  => 'Service[rabbitmq-server-murano]',
  owner   => 'root',
  path    => '/etc/rabbitmq/rabbitmq-murano.config',
}

file_line { 'murano_client_logging':
  ensure => 'present',
  line   => 'LOGGING['loggers']['muranoclient'] = {'handlers': ['syslog'], 'level': 'ERROR'}',
  name   => 'murano_client_logging',
  path   => '/etc/openstack-dashboard/local_settings.py',
  tag    => 'patch-horizon-config',
}

file_line { 'murano_dashboard_logging':
  ensure => 'present',
  line   => 'LOGGING['loggers']['muranodashboard'] = {'handlers': ['syslog'], 'level': 'DEBUG'}',
  name   => 'murano_dashboard_logging',
  path   => '/etc/openstack-dashboard/local_settings.py',
  tag    => 'patch-horizon-config',
}

file_line { 'murano_max_file_size':
  ensure => 'present',
  line   => 'MAX_FILE_SIZE_MB = '5'',
  name   => 'murano_max_file_size',
  path   => '/etc/openstack-dashboard/local_settings.py',
  tag    => 'patch-horizon-config',
}

file_line { 'murano_metadata_dir':
  ensure => 'present',
  line   => 'METADATA_CACHE_DIR = '/var/cache/muranodashboard-cache'',
  name   => 'murano_metadata_dir',
  path   => '/etc/openstack-dashboard/local_settings.py',
  tag    => 'patch-horizon-config',
}

file_line { 'murano_repo_url':
  ensure => 'present',
  line   => 'MURANO_REPO_URL = 'http://catalog.openstack.org/'',
  name   => 'murano_repo_url',
  path   => '/etc/openstack-dashboard/local_settings.py',
  tag    => 'patch-horizon-config',
}

file_line { 'murano_url':
  ensure => 'present',
  line   => 'MURANO_API_URL = 'http://192.168.0.3:8082'',
  name   => 'murano_url',
  path   => '/etc/openstack-dashboard/local_settings.py',
  tag    => 'patch-horizon-config',
}

firewall { '202 murano-api':
  action => 'accept',
  before => 'Class[Murano::Api]',
  dport  => '8082',
  name   => '202 murano-api',
  proto  => 'tcp',
}

firewall { '203 murano-rabbitmq':
  action => 'accept',
  before => 'Service[rabbitmq-server-murano]',
  dport  => '55572',
  name   => '203 murano-rabbitmq',
  proto  => 'tcp',
}

haproxy_backend_status { 'murano-api':
  name => 'murano-api',
  url  => 'http://192.168.0.2:10000/;csv',
}

murano_config { 'DEFAULT/bind_host':
  name   => 'DEFAULT/bind_host',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => '192.168.0.3',
}

murano_config { 'DEFAULT/bind_port':
  name   => 'DEFAULT/bind_port',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => '8082',
}

murano_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'false',
}

murano_config { 'DEFAULT/log_dir':
  name   => 'DEFAULT/log_dir',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => '/var/log/murano',
}

murano_config { 'DEFAULT/notification_driver':
  name   => 'DEFAULT/notification_driver',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'messagingv2',
}

murano_config { 'DEFAULT/syslog_log_facility':
  name   => 'DEFAULT/syslog_log_facility',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'LOG_LOCAL0',
}

murano_config { 'DEFAULT/use_stderr':
  name   => 'DEFAULT/use_stderr',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'false',
}

murano_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'true',
}

murano_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'true',
}

murano_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'true',
}

murano_config { 'database/connection':
  name   => 'database/connection',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'mysql://murano:R3SuvZbh@192.168.0.2/murano?read_timeout=60',
}

murano_config { 'keystone_authtoken/admin_password':
  name   => 'keystone_authtoken/admin_password',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'xP8WtHQw',
}

murano_config { 'keystone_authtoken/admin_tenant_name':
  name   => 'keystone_authtoken/admin_tenant_name',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'services',
}

murano_config { 'keystone_authtoken/admin_user':
  name   => 'keystone_authtoken/admin_user',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'murano',
}

murano_config { 'keystone_authtoken/auth_uri':
  name   => 'keystone_authtoken/auth_uri',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'https://public.fuel.local:5000/v2.0/',
}

murano_config { 'keystone_authtoken/identity_uri':
  name   => 'keystone_authtoken/identity_uri',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'http://192.168.0.2:35357/',
}

murano_config { 'keystone_authtoken/signing_dir':
  name   => 'keystone_authtoken/signing_dir',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => '/tmp/keystone-signing-muranoapi',
}

murano_config { 'murano/url':
  name   => 'murano/url',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'http://192.168.0.3:8082',
}

murano_config { 'networking/create_router':
  name   => 'networking/create_router',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'true',
}

murano_config { 'networking/external_network':
  name   => 'networking/external_network',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'net04_ext',
}

murano_config { 'networking/router_name':
  name   => 'networking/router_name',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'murano-default-router',
}

murano_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'true',
}

murano_config { 'oslo_messaging_rabbit/rabbit_hosts':
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => '192.168.0.3:5673, 192.168.0.2:5673, 192.168.0.4:5673',
}

murano_config { 'oslo_messaging_rabbit/rabbit_password':
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'c7fQJeSe',
}

murano_config { 'oslo_messaging_rabbit/rabbit_port':
  name   => 'oslo_messaging_rabbit/rabbit_port',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => '5673',
}

murano_config { 'oslo_messaging_rabbit/rabbit_userid':
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'nova',
}

murano_config { 'rabbitmq/host':
  name   => 'rabbitmq/host',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => '10.109.1.2',
}

murano_config { 'rabbitmq/login':
  name   => 'rabbitmq/login',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'murano',
}

murano_config { 'rabbitmq/password':
  name   => 'rabbitmq/password',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => 'Nmn2wr9S',
}

murano_config { 'rabbitmq/port':
  name   => 'rabbitmq/port',
  notify => ['Service[murano-api]', 'Service[murano-engine]'],
  value  => '55572',
}

package { 'murano-api':
  ensure => 'present',
  name   => 'murano-api',
  notify => 'Service[murano-api]',
}

package { 'murano-common':
  ensure => 'present',
  before => 'Package[murano-api]',
  name   => 'murano-common',
  tag    => 'openstack',
}

package { 'murano-dashboard':
  ensure => 'present',
  before => 'Exec[clean_horizon_config]',
  name   => 'murano-dashboard',
  notify => 'Exec[django_collectstatic]',
}

package { 'murano-engine':
  ensure => 'present',
  name   => 'murano-engine',
  notify => 'Service[murano-engine]',
}

package { 'python-muranoclient':
  ensure => 'present',
  name   => 'python-muranoclient',
}

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

package { 'rabbitmq-server':
  ensure   => 'installed',
  before   => 'File[rabbitmq_config]',
  name     => 'rabbitmq-server',
  provider => 'apt',
}

service { 'murano-api':
  ensure  => 'running',
  before  => 'Haproxy_backend_status[murano-api]',
  enable  => 'true',
  name    => 'murano-api',
  require => 'Package[murano-api]',
}

service { 'murano-engine':
  ensure  => 'running',
  enable  => 'true',
  name    => 'murano-engine',
  require => 'Package[murano-engine]',
}

service { 'rabbitmq-server-murano':
  ensure => 'running',
  before => 'Exec[remove_murano_guest]',
  enable => 'true',
  name   => 'rabbit-server-murano',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'murano-api':
  name         => 'murano-api',
  package_name => 'murano',
  service_name => 'murano-api',
}

tweaks::ubuntu_service_override { 'murano-engine':
  name         => 'murano-engine',
  package_name => 'murano',
  service_name => 'murano-engine',
}

