class zabbix::params {

  $role = hiera('role')
  $server = ($role == 'zabbix-server')
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
      $mysql_server_pkg = 'mysql-server-wsrep-5.6'
      $mysql_client_pkg = 'mysql-client-5.6'

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
      $mysql_server_pkg = "MySQL-server-wsrep"
      $mysql_client_pkg = 'MySQL-client-wsrep'

    }
  }

  $internal_address     = hiera('internal_address')
  $public_address       = hiera('public_address')
  $storage_address      = hiera('storage_address')
  $agent_listen_ip      = $internal_address
  $agent_source_ip      = $internal_address
  $agent_listen_port    = '10050'

  $agent_hostname        = $::hostname
  $agent_config_template = 'zabbix/zabbix_agentd.conf.erb'
  $agent_config          = '/etc/zabbix/zabbix_agentd.conf'
  $agent_pid_file        = '/var/run/zabbix/zabbix_agentd.pid'

  $agent_include   = '/etc/zabbix/zabbix_agentd.d'
  $agent_scripts   = '/etc/zabbix/scripts'
  $userparameters  = {}

  #server parameters
  $nodes                = hiera('nodes', {})
  $server_node          = get_server_by_role($nodes, 'zabbix-server')
  if $server_node != '' {
    $server_hostname      = $server_node['fqdn']
    $server_ip            = $server_node['internal_address']
  }
  $zabbix_enabled  = ! empty($server_node)

  $server_listen_port     = '10051'
  $server_include_path    = '/etc/zabbix/agent_server.conf'
  $server_config          = '/etc/zabbix/zabbix_server.conf'
  $server_config_template = 'zabbix/zabbix_server.conf.erb'

  #$server_node_id       = fqdn_rand(1000)
  $server_node_id       = 0
  $server_ensure        = present

  #frontend parameters
  $frontend_ensure      = present
  $frontend_hostname    = $::fqdn
  $frontend_base        = 'zabbix'
  $frontend_vhost_class = 'zabbix::frontend::vhost'
  $frontend_port        = 80
  $frontend_timezone    = $::timezone
  $frontend_config_template  = 'zabbix/zabbix.conf.php.erb'
  $frontend_php_ini_template = 'zabbix/php_ini.erb'

  # credentials
  $zabbix_hash          = hiera('zabbix',{})
  $username             = $zabbix_hash['username']
  $password             = $zabbix_hash['password']
  $password_hash        = md5($password)

  #api parameters
  $api_url              = "http://${server_ip}/${frontend_base}/api_jsonrpc.php"
  $api_username         = $username
  $api_password         = $password
  $api_hash             = {
    'endpoint' => $api_url,
    'username' => $api_username,
    'password' => $api_password,
  }

  #common parameters
  $db_type            = 'MYSQL'
  $db_host            = 'localhost'
  $db_port            = '3306'
  $db_name            = 'zabbix'
  $db_user            = 'zabbix'
  $db_password        = $zabbix_hash['db_password']
  $db_root_password   = $zabbix_hash['db_root_password']

  #zabbix hosts params
  $host_name          = $::fqdn
  $host_ip            = hiera('internal_address')
  $host_groups        = ['ManagedByPuppet']

  #openstack
  $management_vip = hiera('management_vip', undef)
  $deployment_id  = hiera('deployment_id')

  $virtual_cluster_hostname = $server_hostname
  $virtual_cluster_name = "OpenStackCluster${deployment_id}"

  #monitoring VIP settings
  if ($management_vip == undef) {
    $controller     = get_server_by_role($nodes, ['primary-controller', 'controller'])
    $controller_ip  = $internal_address
    $keystone_vip   = $controller_ip
    $db_vip         = $controller_ip
    $nova_vip       = $controller_ip
    $glance_vip     = $controller_ip
    $cinder_vip     = $controller_ip
    $rabbit_vip     = $controller_ip
  } else {
    $keystone_vip   = $management_vip
    $db_vip         = $management_vip
    $nova_vip       = $management_vip
    $glance_vip     = $management_vip
    $cinder_vip     = $management_vip
    $rabbit_vip     = $management_vip
  }

  $access_hash          = hiera('access')
  $access_user          = $access_hash['user']
  $access_password      = $access_hash['password']
  $access_tenant        = $access_hash['tenant']

  $keystone_hash        = hiera('keystone')
  $keystone_db_password = $keystone_hash['db_password']

  $nova_hash            = hiera('nova')
  $nova_db_password     = $nova_hash['db_password']

  $cinder_hash          = hiera('cinder')
  $cinder_db_password   = $cinder_hash['db_password']

  $rabbit_hash          = hiera('rabbit')
  $rabbit_password      = $rabbit_hash['password']

}
