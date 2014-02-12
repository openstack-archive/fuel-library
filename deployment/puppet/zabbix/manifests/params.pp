# == Class: zabbix::params
#
# The zabbix configuration settings.
#
class zabbix::params {

  $aaa = '101'

  case $::operatingsystem {
    'Ubuntu', 'Debian': {
      $agent_package = 'zabbix-agent'
      $server_package = 'zabbix-server-mysql'
      $frontend_package     = 'zabbix-frontend-php'

      $agent_service_name = 'zabbix-agent'
      $server_service_name = 'zabbix-server'
      
      $agent_log_file     = '/var/log/zabbix/zabbix_agentd.log'
      $server_log_file     = '/var/log/zabbix-server/zabbix_server.log'

      $frontend_conf_file   = '/etc/zabbix/web/zabbix.conf.php'
      $php_ini_file = '/etc/php5/conf.d/zabbix.ini'

      $prepare_schema_command = 'cat /usr/share/zabbix-server-mysql/schema.sql /usr/share/zabbix-server-mysql/images.sql > /tmp/zabbix-schema-tmp/all.sql'

      $http_service = 'apache2'
    }
    'CentOS', 'RedHat': {

      $agent_package = 'zabbix-agent'
      $server_package = 'zabbix-server-mysql'
      $frontend_package     = 'zabbix-web-mysql'

      $agent_service_name = 'zabbix-agent'
      $server_service_name = 'zabbix-server'

      $agent_log_file     = '/var/log/zabbix/zabbix_agentd.log'
      $server_log_file     = '/var/log/zabbix/zabbix_server.log'

      $frontend_conf_file   = '/etc/zabbix/web/zabbix.conf.php'
      $php_ini_file = '/etc/php.d/zabbix.ini'

      $prepare_schema_command = 'cat /usr/share/doc/zabbix-server-mysql-`zabbix_server -V | awk \'/v[0-9].[0-9].[0-9]/{print substr($3, 2)}\'`/create/schema.sql /usr/share/doc/zabbix-server-mysql-`zabbix_server -V | awk \'/v[0-9].[0-9].[0-9]/{print substr($3, 2)}\'`/create/images.sql > /tmp/zabbix-schema-tmp/all.sql'

      $http_service = 'httpd'
    }
  }
  
  $agent_listen_ip      = $::internal_address
  $agent_source_ip      = $::internal_address
  $agent_listen_port    = '10050'
  
  $agent_hostname       = $::hostname
  $agent_template       = 'zabbix/zabbix_agentd.conf.erb'
  $agent_conf_file      = '/etc/zabbix/zabbix_agentd.conf'
  $agent_pid_file       = '/var/run/zabbix/zabbix_agentd.pid'
  
  $agent_include_path   = '/etc/zabbix/zabbix_agentd.d'
  $agent_scripts_path   = '/etc/zabbix/scripts'
  $userparameters       = {}

  #server parameters
  $server_node          = get_server_by_role($::fuel_settings['nodes'], 'zabbix-server')
  $server_hostname      = $server_node['fqdn']
  $server_ip            = $server_node['internal_address']
  notice("zabbix DEBUG: server node name/ip: $server_hostname/$server_ip")
  $server_listen_port   = '10051'
  $server_include_path  = '/etc/zabbix/agent_server.conf'
  $server_conf_file     = '/etc/zabbix/zabbix_server.conf'
  $server_template      = 'zabbix/zabbix_server.conf.erb'
  
  #$server_node_id       = fqdn_rand(1000)
  $server_node_id       = 0
  $server_ensure        = present

  #frontend parameters
  $frontend_ensure      = present
  $frontend_hostname    = $::fqdn
  $frontend_base        = '/zabbix'
  $frontend_vhost_class = 'zabbix::frontend::vhost'
  $frontend_port        = 80
  $frontend_timezone    = $::timezone

  #api parameters
  $api_ensure           = present
  $api_url              = "http://${zabbix::params::server_ip}${zabbix::params::frontend_base}/api_jsonrpc.php"
  $api_username         = 'Admin' 
  $api_password         = 'zabbix'
  $api_http_username    = $api_username
  $api_http_password    = $api_password
  $api_debug            = true


  #reports parameters
  $reports_ensure       = present
  $reports_host         = $server_hostname
  $reports_port         = '10051'
  $reports_sender       = '/usr/bin/zabbix_sender'
  
  $export_ensure        = present

  #common parameters
  $version            = $::zabbixversion
  $db_type            = 'MYSQL'
  $db_host            = 'localhost'
  $db_port            = '3306'
  $db_name            = 'zabbix'
  $db_user            = 'zabbix'
  $db_password        = $::fuel_settings['zabbix']['db_password']
  $db_root_password   = $::fuel_settings['zabbix']['db_root_password']
  
  #monitoring VIP settings
  if ($::management_vip == undef) {
    $controller     = get_server_by_role($::fuel_settings['nodes'], 'controller')
    $controller_ip  = $controller['internal_address']
    $keystone_vip   = $controller_ip
    $db_vip         = $controller_ip
    $nova_vip       = $controller_ip
    $glance_vip     = $controller_ip
    $cinder_vip     = $controller_ip
    $rabbit_vip     = $controller_ip
  } else {
    $keystone_vip   = $::management_vip
    $db_vip         = $::management_vip
    $nova_vip       = $::management_vip
    $glance_vip     = $::management_vip
    $cinder_vip     = $::management_vip
    $rabbit_vip     = $::management_vip
  }
}
