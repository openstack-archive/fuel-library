class zabbix::params {

  include zabbix::params::openstack

  case $::operatingsystem {
    'Ubuntu', 'Debian': {
      $agent_pkg = 'zabbix-agent'
      $server_pkg = 'zabbix-server-mysql'
      $frontend_pkg = 'zabbix-frontend-php'

      $agent_service = 'zabbix-agent'
      $server_service = 'zabbix-server'

      $agent_log_file = '/var/log/zabbix/zabbix_agentd.log'
      $server_log_file = '/var/log/zabbix-server/zabbix_server.log'

      $frontend_config = '/etc/zabbix/web/zabbix.conf.php'
      $frontend_php_ini = '/etc/php5/conf.d/zabbix.ini'

      $prepare_schema_cmd = 'cat /usr/share/zabbix-server-mysql/schema.sql /usr/share/zabbix-server-mysql/images.sql > /tmp/zabbix/schema.sql'

      $frontend_service = 'apache2'
      $mysql_server_pkg = 'mysql-server-wsrep'

    }
    'CentOS', 'RedHat': {

      $agent_pkg = 'zabbix-agent'
      $server_pkg = 'zabbix-server-mysql'
      $frontend_pkg = 'zabbix-web-mysql'

      $agent_service = 'zabbix-agent'
      $server_service = 'zabbix-server'

      $agent_log_file = '/var/log/zabbix/zabbix_agentd.log'
      $server_log_file = '/var/log/zabbix/zabbix_server.log'

      $frontend_config = '/etc/zabbix/web/zabbix.conf.php'
      $frontend_php_ini = '/etc/php.d/zabbix.ini'

      $prepare_schema_cmd = 'cat /usr/share/doc/zabbix-server-mysql-`zabbix_server -V | awk \'/v[0-9].[0-9].[0-9]/{print substr($3, 2)}\'`/create/schema.sql /usr/share/doc/zabbix-server-mysql-`zabbix_server -V | awk \'/v[0-9].[0-9].[0-9]/{print substr($3, 2)}\'`/create/images.sql > /tmp/zabbix/schema.sql'

      $frontend_service = 'httpd'
      $mysql_server_pkg = 'mysql-server-wsrep'

    }
  }

  $agent_listen_ip      = $::internal_address
  $agent_source_ip      = $::internal_address

  $agent_config_template = 'zabbix/zabbix_agentd.conf.erb'
  $agent_config          = '/etc/zabbix/zabbix_agentd.conf'
  $agent_pid_file        = '/var/run/zabbix/zabbix_agentd.pid'

  $agent_include      = '/etc/zabbix/zabbix_agentd.d'
  $agent_scripts      = '/etc/zabbix/scripts'
  $has_userparameters = true

  #server parameters
  $server_config          = '/etc/zabbix/zabbix_server.conf'
  $server_config_template = 'zabbix/zabbix_server.conf.erb'
  $server_node_id         = 0
  $server_ensure          = present

  #frontend parameters
  $frontend                  = true
  $frontend_ensure           = present
  $frontend_base             = '/zabbix'
  $frontend_config_template  = 'zabbix/zabbix.conf.php.erb'
  $frontend_php_ini_template = 'zabbix/php_ini.erb'

  #common parameters
  $version            = $::zabbixversion
  $db_type            = 'MYSQL'
  $db_port            = '3306'
  $db_name            = 'zabbix'
  $db_user            = 'zabbix'

  #zabbix hosts params
  $host_name              = $::fqdn
  $host_ip                = $::internal_address
  $host_groups            = ['ManagedByPuppet', 'Controllers', 'Computes']
  $host_groups_base       = ['ManagedByPuppet']
  $host_groups_controller = ['Controllers']
  $host_groups_compute    = ['Computes']
}
