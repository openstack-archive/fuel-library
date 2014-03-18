class zabbix::params {

  include zabbix::params::openstack

  # $enabled = $::fuel_settings['zabbix']['enabled']
  $server  = ($::fuel_settings['role'] == 'zabbix-server')
  $frontend = true

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
    }
  }

  $agent_listen_ip      = $::internal_address
  $agent_source_ip      = $::internal_address
  $agent_listen_port    = '10050'

  $agent_hostname       = $::hostname
  $agent_config_template       = 'zabbix/zabbix_agentd.conf.erb'
  $agent_config      = '/etc/zabbix/zabbix_agentd.conf'
  $agent_pid_file       = '/var/run/zabbix/zabbix_agentd.pid'

  $agent_include   = '/etc/zabbix/zabbix_agentd.d'
  $agent_scripts   = '/etc/zabbix/scripts'
  $userparameters       = {}

  #server parameters
  $server_node          = get_server_by_role($::fuel_settings['nodes'], 'zabbix-server')
  $server_hostname      = $server_node['fqdn']
  $server_ip            = $server_node['internal_address']
  $server_listen_port   = '10051'
  $server_include_path  = '/etc/zabbix/agent_server.conf'
  $server_config     = '/etc/zabbix/zabbix_server.conf'
  $server_config_template = 'zabbix/zabbix_server.conf.erb'

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
  $frontend_config_template = 'zabbix/zabbix.conf.php.erb'
  $frontend_php_ini_template = 'zabbix/php_ini.erb'

  # credentials
  $username             = $::fuel_settings['zabbix']['username']
  $password             = $::fuel_settings['zabbix']['password']
  $password_hash        = md5($password)

  #api parameters
  $api_url              = "http://${zabbix::params::server_ip}${zabbix::params::frontend_base}/api_jsonrpc.php"
  $api_username         = $username
  $api_password         = $password
  $api_hash             = { endpoint => $api_url,
                            username => $api_username,
                            password => $api_password }

  #common parameters
  $version            = $::zabbixversion
  $db_type            = 'MYSQL'
  $db_host            = 'localhost'
  $db_port            = '3306'
  $db_name            = 'zabbix'
  $db_user            = 'zabbix'
  $db_password        = $::fuel_settings['zabbix']['db_password']
  $db_root_password   = $::fuel_settings['zabbix']['db_root_password']

  #zabbix hosts params
  $host_name          = $::fqdn
  $host_ip            = $::internal_address
  $host_groups        = ['ManagedByPuppet']
}
