apache::listen { '35357':
  name => '35357',
}

apache::listen { '5000':
  name => '5000',
}

apache::listen { '80':
  name => '80',
}

apache::listen { '8888':
  name => '8888',
}

apache::mod { 'access_compat':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'access_compat',
  package_ensure => 'present',
}

apache::mod { 'alias':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'alias',
  package_ensure => 'present',
}

apache::mod { 'auth_basic':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'auth_basic',
  package_ensure => 'present',
}

apache::mod { 'authn_core':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'authn_core',
  package_ensure => 'present',
}

apache::mod { 'authn_file':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'authn_file',
  package_ensure => 'present',
}

apache::mod { 'authz_core':
  id             => 'authz_core_module',
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'authz_core',
  package_ensure => 'present',
}

apache::mod { 'authz_groupfile':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'authz_groupfile',
  package_ensure => 'present',
}

apache::mod { 'authz_host':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'authz_host',
  package_ensure => 'present',
}

apache::mod { 'authz_user':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'authz_user',
  package_ensure => 'present',
}

apache::mod { 'autoindex':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'autoindex',
  package_ensure => 'present',
}

apache::mod { 'dav':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'dav',
  package_ensure => 'present',
}

apache::mod { 'dav_fs':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'dav_fs',
  package_ensure => 'present',
}

apache::mod { 'deflate':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'deflate',
  package_ensure => 'present',
}

apache::mod { 'dir':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'dir',
  package_ensure => 'present',
}

apache::mod { 'env':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'env',
  package_ensure => 'present',
}

apache::mod { 'filter':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'filter',
  package_ensure => 'present',
}

apache::mod { 'headers':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'headers',
  package_ensure => 'present',
}

apache::mod { 'mime':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'mime',
  package_ensure => 'present',
}

apache::mod { 'negotiation':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'negotiation',
  package_ensure => 'present',
}

apache::mod { 'reqtimeout':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'reqtimeout',
  package_ensure => 'present',
}

apache::mod { 'setenvif':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'setenvif',
  package_ensure => 'present',
}

apache::mod { 'wsgi':
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'wsgi',
  package_ensure => 'present',
}

apache::namevirtualhost { '*:35357':
  name => '*:35357',
}

apache::namevirtualhost { '*:5000':
  name => '*:5000',
}

apache::namevirtualhost { '*:80':
  name => '*:80',
}

apache::namevirtualhost { '*:8888':
  name => '*:8888',
}

apache::vhost { 'default-ssl':
  ensure               => 'absent',
  access_log           => 'true',
  access_log_env_var   => 'false',
  access_log_file      => 'ssl_access.log',
  access_log_format    => 'false',
  access_log_pipe      => 'false',
  access_log_syslog    => 'false',
  add_listen           => 'true',
  additional_includes  => [],
  apache_version       => '2.4',
  block                => [],
  default_vhost        => 'false',
  directoryindex       => '',
  docroot              => '/var/www',
  docroot_group        => 'root',
  docroot_owner        => 'root',
  error_documents      => [],
  error_log            => 'true',
  ip_based             => 'false',
  logroot              => '/var/log/apache2',
  logroot_ensure       => 'directory',
  manage_docroot       => 'false',
  name                 => 'default-ssl',
  no_proxy_uris        => [],
  no_proxy_uris_match  => [],
  options              => ['Indexes', 'FollowSymLinks', 'MultiViews'],
  override             => 'None',
  php_admin_flags      => {},
  php_admin_values     => {},
  php_flags            => {},
  php_values           => {},
  port                 => '443',
  priority             => '15',
  proxy_error_override => 'false',
  proxy_preserve_host  => 'false',
  redirect_source      => '/',
  scriptalias          => '/usr/lib/cgi-bin',
  scriptaliases        => {'alias' => '/cgi-bin', 'path' => '/usr/lib/cgi-bin'},
  serveradmin          => 'root@localhost',
  serveraliases        => [],
  servername           => 'default-ssl',
  setenv               => [],
  setenvif             => [],
  ssl                  => 'true',
  ssl_cert             => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  ssl_certs_dir        => '/etc/ssl/certs',
  ssl_key              => '/etc/ssl/private/ssl-cert-snakeoil.key',
  ssl_proxyengine      => 'false',
  suphp_addhandler     => 'x-httpd-php',
  suphp_configpath     => '/etc/php5/apache2',
  suphp_engine         => 'off',
  vhost_name           => '*',
  virtual_docroot      => 'false',
}

apache::vhost { 'default':
  ensure               => 'absent',
  access_log           => 'true',
  access_log_env_var   => 'false',
  access_log_file      => 'access.log',
  access_log_format    => 'false',
  access_log_pipe      => 'false',
  access_log_syslog    => 'false',
  add_listen           => 'true',
  additional_includes  => [],
  apache_version       => '2.4',
  block                => [],
  default_vhost        => 'false',
  directoryindex       => '',
  docroot              => '/var/www',
  docroot_group        => 'root',
  docroot_owner        => 'root',
  error_documents      => [],
  error_log            => 'true',
  ip_based             => 'false',
  logroot              => '/var/log/apache2',
  logroot_ensure       => 'directory',
  manage_docroot       => 'false',
  name                 => 'default',
  no_proxy_uris        => [],
  no_proxy_uris_match  => [],
  options              => ['Indexes', 'FollowSymLinks', 'MultiViews'],
  override             => 'None',
  php_admin_flags      => {},
  php_admin_values     => {},
  php_flags            => {},
  php_values           => {},
  port                 => '80',
  priority             => '15',
  proxy_error_override => 'false',
  proxy_preserve_host  => 'false',
  redirect_source      => '/',
  scriptalias          => '/usr/lib/cgi-bin',
  scriptaliases        => {'alias' => '/cgi-bin', 'path' => '/usr/lib/cgi-bin'},
  serveradmin          => 'root@localhost',
  serveraliases        => [],
  servername           => 'default',
  setenv               => [],
  setenvif             => [],
  ssl                  => 'false',
  ssl_cert             => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  ssl_certs_dir        => '/etc/ssl/certs',
  ssl_key              => '/etc/ssl/private/ssl-cert-snakeoil.key',
  ssl_proxyengine      => 'false',
  suphp_addhandler     => 'x-httpd-php',
  suphp_configpath     => '/etc/php5/apache2',
  suphp_engine         => 'off',
  vhost_name           => '*',
  virtual_docroot      => 'false',
}

apache::vhost { 'horizon_ssl_vhost':
  ensure                      => 'absent',
  access_log                  => 'true',
  access_log_env_var          => 'false',
  access_log_file             => 'horizon_ssl_access.log',
  access_log_format           => 'false',
  access_log_pipe             => 'false',
  access_log_syslog           => 'false',
  add_listen                  => 'false',
  additional_includes         => [],
  aliases                     => {'alias' => '/horizon/static', 'path' => '/usr/share/openstack-dashboard/static'},
  apache_version              => '2.4',
  block                       => [],
  custom_fragment             => '
<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Order allow,deny
  Allow from all
</Directory>

',
  default_vhost               => 'true',
  directoryindex              => '',
  docroot                     => '/var/www/',
  docroot_group               => 'root',
  docroot_owner               => 'root',
  error_documents             => [],
  error_log                   => 'true',
  error_log_file              => 'horizon_ssl_error.log',
  headers                     => ['set X-XSS-Protection "1; mode=block"', 'set X-Content-Type-Options nosniff', 'always append X-Frame-Options SAMEORIGIN'],
  ip                          => '192.168.0.3',
  ip_based                    => 'false',
  logroot                     => '/var/log/apache2',
  logroot_ensure              => 'directory',
  manage_docroot              => 'true',
  name                        => 'horizon_ssl_vhost',
  no_proxy_uris               => [],
  no_proxy_uris_match         => [],
  options                     => '-Indexes',
  override                    => 'None',
  php_admin_flags             => {},
  php_admin_values            => {},
  php_flags                   => {},
  php_values                  => {},
  port                        => '443',
  priority                    => 'false',
  proxy_error_override        => 'false',
  proxy_preserve_host         => 'false',
  redirect_source             => '/',
  redirectmatch_dest          => '/horizon',
  redirectmatch_regexp        => '^/$',
  redirectmatch_status        => 'permanent',
  scriptaliases               => [],
  serveraliases               => 'node-125.test.domain.local',
  servername                  => 'node-125.test.domain.local',
  setenv                      => [],
  setenvif                    => 'X-Forwarded-Proto https HTTPS=1',
  ssl                         => 'true',
  ssl_cert                    => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  ssl_certs_dir               => '/etc/ssl/certs',
  ssl_key                     => '/etc/ssl/private/ssl-cert-snakeoil.key',
  ssl_proxyengine             => 'false',
  suphp_addhandler            => 'x-httpd-php',
  suphp_configpath            => '/etc/php5/apache2',
  suphp_engine                => 'off',
  vhost_name                  => '*',
  virtual_docroot             => 'false',
  wsgi_daemon_process         => 'horizon-ssl',
  wsgi_daemon_process_options => {'group' => 'horizon', 'processes' => '4', 'threads' => '15', 'user' => 'horizon'},
  wsgi_import_script          => '/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi',
  wsgi_process_group          => 'horizon-ssl',
  wsgi_script_aliases         => {'/horizon' => '/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi'},
}

apache::vhost { 'horizon_vhost':
  ensure                      => 'present',
  access_log                  => 'true',
  access_log_env_var          => 'false',
  access_log_file             => 'horizon_access.log',
  access_log_format           => 'false',
  access_log_pipe             => 'false',
  access_log_syslog           => 'false',
  add_listen                  => 'false',
  additional_includes         => [],
  aliases                     => {'alias' => '/horizon/static', 'path' => '/usr/share/openstack-dashboard/static'},
  apache_version              => '2.4',
  block                       => [],
  custom_fragment             => '
<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Order allow,deny
  Allow from all
</Directory>

',
  default_vhost               => 'true',
  directoryindex              => '',
  docroot                     => '/var/www/',
  docroot_group               => 'root',
  docroot_owner               => 'root',
  error_documents             => [],
  error_log                   => 'true',
  error_log_file              => 'horizon_error.log',
  headers                     => ['set X-XSS-Protection "1; mode=block"', 'set X-Content-Type-Options nosniff', 'always append X-Frame-Options SAMEORIGIN'],
  ip                          => '192.168.0.3',
  ip_based                    => 'false',
  logroot                     => '/var/log/apache2',
  logroot_ensure              => 'directory',
  manage_docroot              => 'true',
  name                        => 'horizon_vhost',
  no_proxy_uris               => [],
  no_proxy_uris_match         => [],
  options                     => '-Indexes',
  override                    => 'None',
  php_admin_flags             => {},
  php_admin_values            => {},
  php_flags                   => {},
  php_values                  => {},
  port                        => '80',
  priority                    => 'false',
  proxy_error_override        => 'false',
  proxy_preserve_host         => 'false',
  redirect_source             => '/',
  redirectmatch_dest          => '/horizon',
  redirectmatch_regexp        => '^/$',
  redirectmatch_status        => 'permanent',
  scriptaliases               => [],
  serveraliases               => 'node-125.test.domain.local',
  servername                  => 'node-125.test.domain.local',
  setenv                      => [],
  setenvif                    => 'X-Forwarded-Proto https HTTPS=1',
  ssl                         => 'false',
  ssl_cert                    => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  ssl_certs_dir               => '/etc/ssl/certs',
  ssl_key                     => '/etc/ssl/private/ssl-cert-snakeoil.key',
  ssl_proxyengine             => 'false',
  suphp_addhandler            => 'x-httpd-php',
  suphp_configpath            => '/etc/php5/apache2',
  suphp_engine                => 'off',
  vhost_name                  => '*',
  virtual_docroot             => 'false',
  wsgi_daemon_process         => 'horizon',
  wsgi_daemon_process_options => {'group' => 'horizon', 'processes' => '4', 'threads' => '15', 'user' => 'horizon'},
  wsgi_import_script          => '/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi',
  wsgi_process_group          => 'horizon',
  wsgi_script_aliases         => {'/horizon' => '/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi'},
}

class { 'Apache::Default_confd_files':
  all  => 'true',
  name => 'Apache::Default_confd_files',
}

class { 'Apache::Default_mods':
  all            => 'true',
  apache_version => '2.4',
  name           => 'Apache::Default_mods',
}

class { 'Apache::Mod::Alias':
  apache_version => '2.4',
  icons_options  => 'Indexes MultiViews',
  name           => 'Apache::Mod::Alias',
}

class { 'Apache::Mod::Authn_core':
  apache_version => '2.4',
  name           => 'Apache::Mod::Authn_core',
}

class { 'Apache::Mod::Authn_file':
  name => 'Apache::Mod::Authn_file',
}

class { 'Apache::Mod::Authz_user':
  name => 'Apache::Mod::Authz_user',
}

class { 'Apache::Mod::Autoindex':
  name => 'Apache::Mod::Autoindex',
}

class { 'Apache::Mod::Dav':
  before => 'Class[Apache::Mod::Dav_fs]',
  name   => 'Apache::Mod::Dav',
}

class { 'Apache::Mod::Dav_fs':
  name => 'Apache::Mod::Dav_fs',
}

class { 'Apache::Mod::Deflate':
  name  => 'Apache::Mod::Deflate',
  notes => {'Input' => 'instream', 'Output' => 'outstream', 'Ratio' => 'ratio'},
  types => ['text/html text/plain text/xml', 'text/css', 'application/x-javascript application/javascript application/ecmascript', 'application/rss+xml'],
}

class { 'Apache::Mod::Dir':
  dir     => 'public_html',
  indexes => ['index.html', 'index.html.var', 'index.cgi', 'index.pl', 'index.php', 'index.xhtml'],
  name    => 'Apache::Mod::Dir',
}

class { 'Apache::Mod::Filter':
  name => 'Apache::Mod::Filter',
}

class { 'Apache::Mod::Headers':
  name => 'Apache::Mod::Headers',
}

class { 'Apache::Mod::Mime':
  mime_support_package => 'mime-support',
  mime_types_config    => '/etc/mime.types',
  name                 => 'Apache::Mod::Mime',
}

class { 'Apache::Mod::Negotiation':
  force_language_priority => 'Prefer Fallback',
  language_priority       => ['en', 'ca', 'cs', 'da', 'de', 'el', 'eo', 'es', 'et', 'fr', 'he', 'hr', 'it', 'ja', 'ko', 'ltz', 'nl', 'nn', 'no', 'pl', 'pt', 'pt-BR', 'ru', 'sv', 'zh-CN', 'zh-TW'],
  name                    => 'Apache::Mod::Negotiation',
}

class { 'Apache::Mod::Reqtimeout':
  name     => 'Apache::Mod::Reqtimeout',
  timeouts => ['header=20-40,minrate=500', 'body=10,minrate=500'],
}

class { 'Apache::Mod::Setenvif':
  name => 'Apache::Mod::Setenvif',
}

class { 'Apache::Mod::Wsgi':
  name => 'Apache::Mod::Wsgi',
}

class { 'Apache::Params':
  name => 'Apache::Params',
}

class { 'Apache::Service':
  name           => 'Apache::Service',
  service_enable => 'true',
  service_ensure => 'running',
  service_manage => 'true',
  service_name   => 'apache2',
}

class { 'Apache::Version':
  name => 'Apache::Version',
}

class { 'Apache':
  a                      => '1',
  apache_name            => 'apache2',
  apache_version         => '2.4',
  conf_dir               => '/etc/apache2',
  conf_template          => 'apache/httpd.conf.erb',
  confd_dir              => '/etc/apache2/conf.d',
  default_confd_files    => 'true',
  default_mods           => 'true',
  default_ssl_cert       => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  default_ssl_key        => '/etc/ssl/private/ssl-cert-snakeoil.key',
  default_ssl_vhost      => 'false',
  default_type           => 'none',
  default_vhost          => 'false',
  docroot                => '/var/www',
  error_documents        => 'false',
  group                  => 'www-data',
  httpd_dir              => '/etc/apache2',
  keepalive              => 'Off',
  keepalive_timeout      => '15',
  lib_path               => '/usr/lib/apache2/modules',
  log_formats            => {},
  log_level              => 'warn',
  logroot                => '/var/log/apache2',
  manage_group           => 'true',
  manage_user            => 'true',
  max_keepalive_requests => '100',
  mod_dir                => '/etc/apache2/mods-available',
  mod_enable_dir         => '/etc/apache2/mods-enabled',
  mpm_module             => 'false',
  name                   => 'Apache',
  package_ensure         => 'installed',
  ports_file             => '/etc/apache2/ports.conf',
  purge_configs          => 'false',
  purge_vdir             => 'false',
  sendfile               => 'On',
  server_root            => '/etc/apache2',
  server_signature       => 'Off',
  server_tokens          => 'Prod',
  serveradmin            => 'root@localhost',
  servername             => 'node-125',
  service_enable         => 'true',
  service_ensure         => 'running',
  service_manage         => 'true',
  service_name           => 'apache2',
  timeout                => '120',
  trace_enable           => 'Off',
  use_optional_includes  => 'false',
  user                   => 'www-data',
  vhost_dir              => '/etc/apache2/sites-available',
  vhost_enable_dir       => '/etc/apache2/sites-enabled',
}

class { 'Concat::Setup':
  name => 'Concat::Setup',
}

class { 'Horizon::Params':
  name => 'Horizon::Params',
}

class { 'Horizon::Wsgi::Apache':
  bind_address        => '192.168.0.3',
  extra_params        => {'add_listen' => 'false', 'custom_fragment' => '
<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Order allow,deny
  Allow from all
</Directory>

', 'default_vhost' => 'true', 'headers' => ['set X-XSS-Protection "1; mode=block"', 'set X-Content-Type-Options nosniff', 'always append X-Frame-Options SAMEORIGIN'], 'options' => '-Indexes', 'setenvif' => 'X-Forwarded-Proto https HTTPS=1'},
  listen_ssl          => 'false',
  name                => 'Horizon::Wsgi::Apache',
  notify              => 'Service[apache2]',
  priority            => 'false',
  redirect_type       => 'permanent',
  server_aliases      => 'node-125.test.domain.local',
  servername          => 'node-125.test.domain.local',
  ssl_redirect        => 'true',
  vhost_conf_name     => 'horizon_vhost',
  vhost_ssl_conf_name => 'horizon_ssl_vhost',
  wsgi_processes      => '4',
  wsgi_threads        => '15',
}

class { 'Horizon':
  allowed_hosts                  => '*',
  api_result_limit               => '1000',
  api_versions                   => {},
  bind_address                   => '192.168.0.3',
  cache_backend                  => 'django.core.cache.backends.memcached.MemcachedCache',
  cache_options                  => {'DEAD_RETRY' => '1', 'SERVER_RETRIES' => '1', 'SOCKET_TIMEOUT' => '1'},
  cache_server_ip                => '192.168.0.3',
  cache_server_port              => '11211',
  cinder_options                 => {},
  compress_offline               => 'true',
  configure_apache               => 'false',
  django_debug                   => 'false',
  django_session_engine          => 'django.contrib.sessions.backends.cache',
  file_upload_temp_dir           => '/tmp',
  help_url                       => 'http://docs.openstack.org',
  horizon_app_links              => 'false',
  hypervisor_options             => {},
  keystone_default_role          => '_member_',
  keystone_multidomain_support   => 'false',
  keystone_url                   => 'http://192.168.0.7:5000/v2.0',
  listen_ssl                     => 'false',
  local_settings_template        => 'horizon/local_settings.py.erb',
  log_handler                    => 'file',
  log_level                      => 'INFO',
  name                           => 'Horizon',
  neutron_options                => {'enable_distributed_router' => 'false'},
  package_ensure                 => 'installed',
  redirect_type                  => 'temp',
  secret_key                     => 'dummy_secret_key',
  secure_cookies                 => 'false',
  server_aliases                 => 'node-125.test.domain.local',
  servername                     => 'node-125.test.domain.local',
  ssl_no_verify                  => 'true',
  ssl_redirect                   => 'true',
  tuskar_ui                      => 'false',
  tuskar_ui_deployment_mode      => 'scale',
  tuskar_ui_ironic_discoverd_url => 'http://127.0.0.1:5050',
}

class { 'Openstack::Horizon':
  apache_options        => '-Indexes',
  api_result_limit      => '1000',
  before                => ['Haproxy_backend_status[keystone-admin]', 'Haproxy_backend_status[keystone-public]'],
  bind_address          => '192.168.0.3',
  cache_backend         => 'django.core.cache.backends.memcached.MemcachedCache',
  cache_options         => {'DEAD_RETRY' => '1', 'SERVER_RETRIES' => '1', 'SOCKET_TIMEOUT' => '1'},
  cache_server_ip       => '192.168.0.3',
  cache_server_port     => '11211',
  debug                 => 'false',
  django_session_engine => 'django.contrib.sessions.backends.cache',
  headers               => ['set X-XSS-Protection "1; mode=block"', 'set X-Content-Type-Options nosniff', 'always append X-Frame-Options SAMEORIGIN'],
  keystone_default_role => '_member_',
  keystone_url          => 'http://192.168.0.7:5000/v2.0',
  log_handler           => 'file',
  log_level             => 'WARNING',
  name                  => 'Openstack::Horizon',
  neutron               => 'true',
  neutron_options       => {'enable_distributed_router' => 'false'},
  nova_quota            => 'false',
  package_ensure        => 'installed',
  secret_key            => 'dummy_secret_key',
  servername            => '172.16.0.3',
  ssl_no_verify         => 'true',
  use_ssl               => 'false',
  use_syslog            => 'true',
  verbose               => 'true',
}

class { 'Osnailyfacter::Apache':
  listen_ports     => ['80', '8888', '5000', '35357'],
  logrotate_rotate => '52',
  name             => 'Osnailyfacter::Apache',
  purge_configs    => 'false',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Tweaks::Apache_wrappers':
  name => 'Tweaks::Apache_wrappers',
}

class { 'main':
  name => 'main',
}

concat::fragment { 'Apache ports header':
  ensure  => 'present',
  content => '# ************************************
# Listen & NameVirtualHost resources in module puppetlabs-apache
# Managed by Puppet
# ************************************

',
  name    => 'Apache ports header',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'Listen 35357':
  ensure  => 'present',
  content => 'Listen 35357
',
  name    => 'Listen 35357',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'Listen 5000':
  ensure  => 'present',
  content => 'Listen 5000
',
  name    => 'Listen 5000',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'Listen 80':
  ensure  => 'present',
  content => 'Listen 80
',
  name    => 'Listen 80',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'Listen 8888':
  ensure  => 'present',
  content => 'Listen 8888
',
  name    => 'Listen 8888',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'NameVirtualHost *:35357':
  ensure  => 'present',
  content => 'NameVirtualHost *:35357
',
  name    => 'NameVirtualHost *:35357',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'NameVirtualHost *:5000':
  ensure  => 'present',
  content => 'NameVirtualHost *:5000
',
  name    => 'NameVirtualHost *:5000',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'NameVirtualHost *:80':
  ensure  => 'present',
  content => 'NameVirtualHost *:80
',
  name    => 'NameVirtualHost *:80',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'NameVirtualHost *:8888':
  ensure  => 'present',
  content => 'NameVirtualHost *:8888
',
  name    => 'NameVirtualHost *:8888',
  order   => '10',
  target  => '/etc/apache2/ports.conf',
}

concat::fragment { 'default-access_log':
  content => '  CustomLog "/var/log/apache2/access.log" combined 
',
  name    => 'default-access_log',
  order   => '100',
  target  => '15-default.conf',
}

concat::fragment { 'default-apache-header':
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost *:80>
  ServerName default
  ServerAdmin root@localhost
',
  name    => 'default-apache-header',
  order   => '0',
  target  => '15-default.conf',
}

concat::fragment { 'default-directories':
  content => '
  ## Directories, there should at least be a declaration for /var/www

  <Directory "/var/www">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Require all granted
  </Directory>
',
  name    => 'default-directories',
  order   => '60',
  target  => '15-default.conf',
}

concat::fragment { 'default-docroot':
  content => '
  ## Vhost docroot
  DocumentRoot "/var/www"
',
  name    => 'default-docroot',
  order   => '10',
  target  => '15-default.conf',
}

concat::fragment { 'default-file_footer':
  content => '</VirtualHost>
',
  name    => 'default-file_footer',
  order   => '999',
  target  => '15-default.conf',
}

concat::fragment { 'default-logging':
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/default_error.log"
',
  name    => 'default-logging',
  order   => '80',
  target  => '15-default.conf',
}

concat::fragment { 'default-scriptalias':
  content => '  ## Script alias directives
  ScriptAlias /cgi-bin "/usr/lib/cgi-bin"
',
  name    => 'default-scriptalias',
  order   => '180',
  target  => '15-default.conf',
}

concat::fragment { 'default-serversignature':
  content => '  ServerSignature Off
',
  name    => 'default-serversignature',
  order   => '90',
  target  => '15-default.conf',
}

concat::fragment { 'default-ssl-access_log':
  content => '  CustomLog "/var/log/apache2/ssl_access.log" combined 
',
  name    => 'default-ssl-access_log',
  order   => '100',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'default-ssl-apache-header':
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost *:443>
  ServerName default-ssl
  ServerAdmin root@localhost
',
  name    => 'default-ssl-apache-header',
  order   => '0',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'default-ssl-directories':
  content => '
  ## Directories, there should at least be a declaration for /var/www

  <Directory "/var/www">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Require all granted
  </Directory>
',
  name    => 'default-ssl-directories',
  order   => '60',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'default-ssl-docroot':
  content => '
  ## Vhost docroot
  DocumentRoot "/var/www"
',
  name    => 'default-ssl-docroot',
  order   => '10',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'default-ssl-file_footer':
  content => '</VirtualHost>
',
  name    => 'default-ssl-file_footer',
  order   => '999',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'default-ssl-logging':
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/default-ssl_error_ssl.log"
',
  name    => 'default-ssl-logging',
  order   => '80',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'default-ssl-scriptalias':
  content => '  ## Script alias directives
  ScriptAlias /cgi-bin "/usr/lib/cgi-bin"
',
  name    => 'default-ssl-scriptalias',
  order   => '180',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'default-ssl-serversignature':
  content => '  ServerSignature Off
',
  name    => 'default-ssl-serversignature',
  order   => '90',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'default-ssl-ssl':
  content => '
  ## SSL directives
  SSLEngine on
  SSLCertificateFile      "/etc/ssl/certs/ssl-cert-snakeoil.pem"
  SSLCertificateKeyFile   "/etc/ssl/private/ssl-cert-snakeoil.key"
  SSLCACertificatePath    "/etc/ssl/certs"
',
  name    => 'default-ssl-ssl',
  order   => '210',
  target  => '15-default-ssl.conf',
}

concat::fragment { 'horizon_ssl_vhost-access_log':
  content => '  CustomLog "/var/log/apache2/horizon_ssl_access.log" combined 
',
  name    => 'horizon_ssl_vhost-access_log',
  order   => '100',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-aliases':
  content => '  ## Alias declarations for resources outside the DocumentRoot
  Alias /horizon/static "/usr/share/openstack-dashboard/static"
',
  name    => 'horizon_ssl_vhost-aliases',
  order   => '20',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-apache-header':
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost 192.168.0.3:443>
  ServerName node-125.test.domain.local
',
  name    => 'horizon_ssl_vhost-apache-header',
  order   => '0',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-custom_fragment':
  content => '
  ## Custom fragment

<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Order allow,deny
  Allow from all
</Directory>


',
  name    => 'horizon_ssl_vhost-custom_fragment',
  order   => '270',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-directories':
  content => '
  ## Directories, there should at least be a declaration for /var/www/

  <Directory "/var/www/">
    Options -Indexes
    AllowOverride None
    Require all granted
  </Directory>
',
  name    => 'horizon_ssl_vhost-directories',
  order   => '60',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-docroot':
  content => '
  ## Vhost docroot
  DocumentRoot "/var/www/"
',
  name    => 'horizon_ssl_vhost-docroot',
  order   => '10',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-file_footer':
  content => '</VirtualHost>
',
  name    => 'horizon_ssl_vhost-file_footer',
  order   => '999',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-header':
  content => '
  ## Header rules
  ## as per http://httpd.apache.org/docs/2.2/mod/mod_headers.html#header
  Header set X-XSS-Protection "1; mode=block"
  Header set X-Content-Type-Options nosniff
  Header always append X-Frame-Options SAMEORIGIN
',
  name    => 'horizon_ssl_vhost-header',
  order   => '240',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-logging':
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/horizon_ssl_error.log"
',
  name    => 'horizon_ssl_vhost-logging',
  order   => '80',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-redirect':
  content => '
  ## RedirectMatch rules
  RedirectMatch permanent  ^/$ /horizon
',
  name    => 'horizon_ssl_vhost-redirect',
  order   => '160',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-serveralias':
  content => '
  ## Server aliases
  ServerAlias node-125.test.domain.local
',
  name    => 'horizon_ssl_vhost-serveralias',
  order   => '190',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-serversignature':
  content => '  ServerSignature Off
',
  name    => 'horizon_ssl_vhost-serversignature',
  order   => '90',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-setenv':
  content => '  SetEnvIf X-Forwarded-Proto https HTTPS=1
',
  name    => 'horizon_ssl_vhost-setenv',
  order   => '200',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-ssl':
  content => '
  ## SSL directives
  SSLEngine on
  SSLCertificateFile      "/etc/ssl/certs/ssl-cert-snakeoil.pem"
  SSLCertificateKeyFile   "/etc/ssl/private/ssl-cert-snakeoil.key"
  SSLCACertificatePath    "/etc/ssl/certs"
',
  name    => 'horizon_ssl_vhost-ssl',
  order   => '210',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_ssl_vhost-wsgi':
  content => '  WSGIDaemonProcess horizon-ssl group=horizon processes=4 threads=15 user=horizon
  WSGIProcessGroup horizon-ssl
  WSGIScriptAlias /horizon "/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi"
',
  name    => 'horizon_ssl_vhost-wsgi',
  order   => '260',
  target  => 'horizon_ssl_vhost.conf',
}

concat::fragment { 'horizon_vhost-access_log':
  content => '  CustomLog "/var/log/apache2/horizon_access.log" combined 
',
  name    => 'horizon_vhost-access_log',
  order   => '100',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-aliases':
  content => '  ## Alias declarations for resources outside the DocumentRoot
  Alias /horizon/static "/usr/share/openstack-dashboard/static"
',
  name    => 'horizon_vhost-aliases',
  order   => '20',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-apache-header':
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost 192.168.0.3:80>
  ServerName node-125.test.domain.local
',
  name    => 'horizon_vhost-apache-header',
  order   => '0',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-custom_fragment':
  content => '
  ## Custom fragment

<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Order allow,deny
  Allow from all
</Directory>


',
  name    => 'horizon_vhost-custom_fragment',
  order   => '270',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-directories':
  content => '
  ## Directories, there should at least be a declaration for /var/www/

  <Directory "/var/www/">
    Options -Indexes
    AllowOverride None
    Require all granted
  </Directory>
',
  name    => 'horizon_vhost-directories',
  order   => '60',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-docroot':
  content => '
  ## Vhost docroot
  DocumentRoot "/var/www/"
',
  name    => 'horizon_vhost-docroot',
  order   => '10',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-file_footer':
  content => '</VirtualHost>
',
  name    => 'horizon_vhost-file_footer',
  order   => '999',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-header':
  content => '
  ## Header rules
  ## as per http://httpd.apache.org/docs/2.2/mod/mod_headers.html#header
  Header set X-XSS-Protection "1; mode=block"
  Header set X-Content-Type-Options nosniff
  Header always append X-Frame-Options SAMEORIGIN
',
  name    => 'horizon_vhost-header',
  order   => '240',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-logging':
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/horizon_error.log"
',
  name    => 'horizon_vhost-logging',
  order   => '80',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-redirect':
  content => '
  ## RedirectMatch rules
  RedirectMatch permanent  ^/$ /horizon
',
  name    => 'horizon_vhost-redirect',
  order   => '160',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-serveralias':
  content => '
  ## Server aliases
  ServerAlias node-125.test.domain.local
',
  name    => 'horizon_vhost-serveralias',
  order   => '190',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-serversignature':
  content => '  ServerSignature Off
',
  name    => 'horizon_vhost-serversignature',
  order   => '90',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-setenv':
  content => '  SetEnvIf X-Forwarded-Proto https HTTPS=1
',
  name    => 'horizon_vhost-setenv',
  order   => '200',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'horizon_vhost-wsgi':
  content => '  WSGIDaemonProcess horizon group=horizon processes=4 threads=15 user=horizon
  WSGIProcessGroup horizon
  WSGIScriptAlias /horizon "/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi"
',
  name    => 'horizon_vhost-wsgi',
  order   => '260',
  target  => 'horizon_vhost.conf',
}

concat::fragment { 'local_settings.py':
  content => 'import os

from django.utils.translation import ugettext_lazy as _

from openstack_dashboard import exceptions

DEBUG = False
TEMPLATE_DEBUG = DEBUG

# WEBROOT is the location relative to Webserver root
# should end with a slash.
WEBROOT = '/horizon/'

# Required for Django 1.5.
# If horizon is running in production (DEBUG is False), set this
# with the list of host/domain names that the application can serve.
# For more information see:
# https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts
#ALLOWED_HOSTS = ['horizon.example.com', ]

ALLOWED_HOSTS = ['*', ]


# Set SSL proxy settings:
# For Django 1.4+ pass this header from the proxy after terminating the SSL,
# and don't forget to strip it from the client's request.
# For more information see:
# https://docs.djangoproject.com/en/1.4/ref/settings/#secure-proxy-ssl-header
# SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTOCOL', 'https')

# If Horizon is being served through SSL, then uncomment the following two
# settings to better secure the cookies from security exploits

#CSRF_COOKIE_SECURE = True
#SESSION_COOKIE_SECURE = True


# Overrides for OpenStack API versions. Use this setting to force the
# OpenStack dashboard to use a specfic API version for a given service API.
# NOTE: The version should be formatted as it appears in the URL for the
# service API. For example, The identity service APIs have inconsistent
# use of the decimal point, so valid options would be "2.0" or "3".
# OPENSTACK_API_VERSIONS = {
#     "identity": 3
# }



# Set this to True if running on multi-domain model. When this is enabled, it
# will require user to enter the Domain name in addition to username for login.
# OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False


# Overrides the default domain used when running on single-domain model
# with Keystone V3. All entities will be created in the default domain.
# OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'


# Set Console type:
# valid options would be "AUTO", "VNC" or "SPICE"
# CONSOLE_TYPE = "AUTO"

# Default OpenStack Dashboard configuration.
HORIZON_CONFIG = {
    'dashboards': ('project', 'admin', 'settings',),
    'default_dashboard': 'project',
    'user_home': 'openstack_dashboard.views.get_user_home',
    'ajax_queue_limit': 10,
    'auto_fade_alerts': {
        'delay': 3000,
        'fade_duration': 1500,
        'types': ['alert-success', 'alert-info']
    },
    'help_url': "http://docs.openstack.org",
    'exceptions': {'recoverable': exceptions.RECOVERABLE,
                   'not_found': exceptions.NOT_FOUND,
                   'unauthorized': exceptions.UNAUTHORIZED},
}

# Specify a regular expression to validate user passwords.
# HORIZON_CONFIG["password_validator"] = {
#     "regex": '.*',
#     "help_text": _("Your password does not meet the requirements.")
# }

# Disable simplified floating IP address management for deployments with
# multiple floating IP pools or complex network requirements.
# HORIZON_CONFIG["simple_ip_management"] = False

# Turn off browser autocompletion for the login form if so desired.
# HORIZON_CONFIG["password_autocomplete"] = "off"

LOCAL_PATH = os.path.dirname(os.path.abspath(__file__))

# Set custom secret key:
# You can either set it to a specific value or you can let horizion generate a
# default secret key that is unique on this machine, e.i. regardless of the
# amount of Python WSGI workers (if used behind Apache+mod_wsgi): However, there
# may be situations where you would want to set this explicitly, e.g. when
# multiple dashboard instances are distributed on different machines (usually
# behind a load-balancer). Either you have to make sure that a session gets all
# requests routed to the same dashboard instance or you set the same SECRET_KEY
# for all of them.
# from horizon.utils import secret_key
# SECRET_KEY = secret_key.generate_or_read_from_file(os.path.join(LOCAL_PATH, '.secret_key_store'))
SECRET_KEY = 'dummy_secret_key'

# We recommend you use memcached for development; otherwise after every reload
# of the django development server, you will have to login again. To use
# memcached set CACHES to something like
# CACHES = {
#    'default': {
#        'BACKEND' : 'django.core.cache.backends.memcached.MemcachedCache',
#        'LOCATION' : '127.0.0.1:11211',
#    }
#}

CACHES = {
    'default': {
    
        'OPTIONS': {
                'DEAD_RETRY': 1,
                'SERVER_RETRIES': 1,
                'SOCKET_TIMEOUT': 1,
        },
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
    
          
            
        'LOCATION': [ '192.168.0.3:11211', ],
          
    
    }
}


SESSION_ENGINE = "django.contrib.sessions.backends.cache"


# Send email to the console by default
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
# Or send them to /dev/null
#EMAIL_BACKEND = 'django.core.mail.backends.dummy.EmailBackend'

# Configure these for your outgoing email host
# EMAIL_HOST = 'smtp.my-company.com'
# EMAIL_PORT = 25
# EMAIL_HOST_USER = 'djangomail'
# EMAIL_HOST_PASSWORD = 'top-secret!'

# For multiple regions uncomment this configuration, and add (endpoint, title).

OPENSTACK_KEYSTONE_URL = "http://192.168.0.7:5000/v2.0"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"

# Disable SSL certificate checks (useful for self-signed certificates):
# OPENSTACK_SSL_NO_VERIFY = False

OPENSTACK_SSL_NO_VERIFY = True

# The CA certificate to use to verify SSL connections
# OPENSTACK_SSL_CACERT = '/path/to/cacert.pem'

# The OPENSTACK_KEYSTONE_BACKEND settings can be used to identify the
# capabilities of the auth backend for Keystone.
# If Keystone has been configured to use LDAP as the auth backend then set
# can_edit_user to False and name to 'ldap'.
#
# TODO(tres): Remove these once Keystone has an API to identify auth backend.
OPENSTACK_KEYSTONE_BACKEND = {
    'name': 'native',
    'can_edit_user': True,
    'can_edit_group': True,
    'can_edit_project': True,
    'can_edit_domain': True,
    'can_edit_role': True
}

# The OPENSTACK_HYPERVISOR_FEATURES settings can be used to enable optional
# services provided by hypervisors.
OPENSTACK_HYPERVISOR_FEATURES = {
    'can_set_mount_point': True,
    'can_set_password': False,
}

# The OPENSTACK_CINDER_FEATURES settings can be used to enable optional
# services provided by cinder that is not exposed by its extension API.
OPENSTACK_CINDER_FEATURES = {
    'enable_backup': False,
}

# The OPENSTACK_NEUTRON_NETWORK settings can be used to enable optional
# services provided by neutron. Options currenly available are load
# balancer service, security groups, quotas, VPN service.
# The profile_support option is used to detect if an externa lrouter can be
# configured via the dashboard. When using specific plugins the
# profile_support can be turned on if needed.
OPENSTACK_NEUTRON_NETWORK = {
    'enable_distributed_router': False,
    'enable_firewall': False,
    'enable_ha_router': False,
    'enable_lb': False,
    'enable_quotas': True,
    'enable_security_group': True,
    'enable_vpn': False,
    'profile_support': 'None',
}

# The OPENSTACK_IMAGE_BACKEND settings can be used to customize features
# in the OpenStack Dashboard related to the Image service, such as the list
# of supported image formats.
# OPENSTACK_IMAGE_BACKEND = {
#     'image_formats': [
#         ('', ''),
#         ('aki', _('AKI - Amazon Kernel Image')),
#         ('ami', _('AMI - Amazon Machine Image')),
#         ('ari', _('ARI - Amazon Ramdisk Image')),
#         ('iso', _('ISO - Optical Disk Image')),
#         ('qcow2', _('QCOW2 - QEMU Emulator')),
#         ('raw', _('Raw')),
#         ('vdi', _('VDI')),
#         ('vhd', _('VHD')),
#         ('vmdk', _('VMDK'))
#     ]
# }

# OPENSTACK_ENDPOINT_TYPE specifies the endpoint type to use for the endpoints
# in the Keystone service catalog. Use this setting when Horizon is running
# external to the OpenStack environment. The default is 'publicURL'.
#OPENSTACK_ENDPOINT_TYPE = "publicURL"


# SECONDARY_ENDPOINT_TYPE specifies the fallback endpoint type to use in the
# case that OPENSTACK_ENDPOINT_TYPE is not present in the endpoints
# in the Keystone service catalog. Use this setting when Horizon is running
# external to the OpenStack environment. The default is None.  This
# value should differ from OPENSTACK_ENDPOINT_TYPE if used.
#SECONDARY_ENDPOINT_TYPE = "publicURL"


# The number of objects (Swift containers/objects or images) to display
# on a single page before providing a paging element (a "more" link)
# to paginate results.
API_RESULT_LIMIT = 1000
API_RESULT_PAGE_SIZE = 20

# The timezone of the server. This should correspond with the timezone
# of your entire OpenStack installation, and hopefully be in UTC.
TIME_ZONE = "UTC"

# If you have external monitoring links, eg:


# When launching an instance, the menu of available flavors is
# sorted by RAM usage, ascending.  Provide a callback method here
# (and/or a flag for reverse sort) for the sorted() method if you'd
# like a different behaviour.  For more info, see
# http://docs.python.org/2/library/functions.html#sorted
# CREATE_INSTANCE_FLAVOR_SORT = {
#     'key': my_awesome_callback_method,
#     'reverse': False,
# }

# CUSTOM_THEME_PATH allows to set to the directory location for the
# theme (e.g., "static/themes/blue"). The path can either be
# relative to the openstack_dashboard directory or an absolute path
# to an accessible location on the file system.
# If not specified, the default CUSTOM_THEME_PATH is
# static/themes/default.


# The Horizon Policy Enforcement engine uses these values to load per service
# policy rule files. The content of these files should match the files the
# OpenStack services are using to determine role based access control in the
# target installation.

# Path to directory containing policy.json files

#POLICY_FILES_PATH = os.path.join(ROOT_PATH, "conf")

# Map of local copy of service policy files
#POLICY_FILES = {
#    'identity': 'keystone_policy.json',
#    'compute': 'nova_policy.json'
#}

# Trove user and database extension support. By default support for
# creating users and databases on database instances is turned on.
# To disable these extensions set the permission here to something
# unusable such as ["!"].
# TROVE_ADD_USER_PERMS = []
# TROVE_ADD_DATABASE_PERMS = []

LOGGING = {
    'version': 1,
    # When set to True this will disable all logging except
    # for loggers specified in this configuration dictionary. Note that
    # if nothing is specified here and disable_existing_loggers is True,
    # django.db.backends will still log unless it is disabled explicitly.
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '%(asctime)s %(process)d %(levelname)s %(name)s '
                      '%(message)s'
        },
        'normal': {
            'format': 'dashboard-%(name)s: %(levelname)s %(message)s'
        },
    },
    'handlers': {
        'null': {
            'level': 'DEBUG',
            'class': 'django.utils.log.NullHandler',
        },
        'console': {
            # Set the level to "DEBUG" for verbose output logging.
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/var/log/horizon/horizon.log',
            'formatter': 'verbose',
        },
        'syslog': {
            'level': 'INFO',
            'facility': 'local1',
            'class': 'logging.handlers.SysLogHandler',
            'address': '/dev/log',
            'formatter': 'normal',
        }
    },
    'loggers': {
        # Logging from django.db.backends is VERY verbose, send to null
        # by default.
        'django.db.backends': {
            'handlers': ['null'],
            'propagate': False,
        },
        'requests': {
            'handlers': ['null'],
            'propagate': False,
        },
        'horizon': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'openstack_dashboard': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'novaclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'cinderclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'keystoneclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'glanceclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'neutronclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'heatclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'ceilometerclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'troveclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'swiftclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'openstack_auth': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'nose.plugins.manager': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'django': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
    }
}

SECURITY_GROUP_RULES = {
    'all_tcp': {
        'name': 'ALL TCP',
        'ip_protocol': 'tcp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_udp': {
        'name': 'ALL UDP',
        'ip_protocol': 'udp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_icmp': {
        'name': 'ALL ICMP',
        'ip_protocol': 'icmp',
        'from_port': '-1',
        'to_port': '-1',
    },
    'ssh': {
        'name': 'SSH',
        'ip_protocol': 'tcp',
        'from_port': '22',
        'to_port': '22',
    },
    'smtp': {
        'name': 'SMTP',
        'ip_protocol': 'tcp',
        'from_port': '25',
        'to_port': '25',
    },
    'dns': {
        'name': 'DNS',
        'ip_protocol': 'tcp',
        'from_port': '53',
        'to_port': '53',
    },
    'http': {
        'name': 'HTTP',
        'ip_protocol': 'tcp',
        'from_port': '80',
        'to_port': '80',
    },
    'pop3': {
        'name': 'POP3',
        'ip_protocol': 'tcp',
        'from_port': '110',
        'to_port': '110',
    },
    'imap': {
        'name': 'IMAP',
        'ip_protocol': 'tcp',
        'from_port': '143',
        'to_port': '143',
    },
    'ldap': {
        'name': 'LDAP',
        'ip_protocol': 'tcp',
        'from_port': '389',
        'to_port': '389',
    },
    'https': {
        'name': 'HTTPS',
        'ip_protocol': 'tcp',
        'from_port': '443',
        'to_port': '443',
    },
    'smtps': {
        'name': 'SMTPS',
        'ip_protocol': 'tcp',
        'from_port': '465',
        'to_port': '465',
    },
    'imaps': {
        'name': 'IMAPS',
        'ip_protocol': 'tcp',
        'from_port': '993',
        'to_port': '993',
    },
    'pop3s': {
        'name': 'POP3S',
        'ip_protocol': 'tcp',
        'from_port': '995',
        'to_port': '995',
    },
    'ms_sql': {
        'name': 'MS SQL',
        'ip_protocol': 'tcp',
        'from_port': '1433',
        'to_port': '1433',
    },
    'mysql': {
        'name': 'MYSQL',
        'ip_protocol': 'tcp',
        'from_port': '3306',
        'to_port': '3306',
    },
    'rdp': {
        'name': 'RDP',
        'ip_protocol': 'tcp',
        'from_port': '3389',
        'to_port': '3389',
    },
}

LOGIN_URL = '/horizon/auth/login/'
LOGOUT_URL = '/horizon/auth/logout/'
LOGIN_REDIRECT_URL = '/horizon'

# The Ubuntu package includes pre-compressed JS and compiled CSS to allow
# offline compression by default.  To enable online compression, install
# the python-lesscpy package and disable the following option.
COMPRESS_OFFLINE = True

# For Glance image upload, Horizon uses the file upload support from Django
# so we add this option to change the directory where uploaded files are temporarily
# stored until they are loaded into Glance.
FILE_UPLOAD_TEMP_DIR = '/tmp'



# Horizon doesn't know status of nova quotas. As result user may change
# nova quotas in horizon UI, while actually they are turned off in nova. To avoid such
# confusion ENABLED_QUOTA_GROUPS option were added. LP: 1286099, 1332457
ENABLED_QUOTA_GROUPS = {

    'nova': False

}
',
  name    => 'local_settings.py',
  order   => '50',
  target  => '/etc/openstack-dashboard/local_settings.py',
}

concat { '/etc/apache2/ports.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'root',
  mode           => '0644',
  name           => '/etc/apache2/ports.conf',
  notify         => 'Class[Apache::Service]',
  order          => 'alpha',
  owner          => 'root',
  path           => '/etc/apache2/ports.conf',
  replace        => 'true',
  require        => 'Package[httpd]',
  warn           => 'false',
}

concat { '/etc/openstack-dashboard/local_settings.py':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  mode           => '0644',
  name           => '/etc/openstack-dashboard/local_settings.py',
  notify         => 'Exec[refresh_horizon_django_cache]',
  order          => 'alpha',
  path           => '/etc/openstack-dashboard/local_settings.py',
  replace        => 'true',
  require        => 'Package[horizon]',
  warn           => 'false',
}

concat { '15-default-ssl.conf':
  ensure         => 'absent',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'root',
  mode           => '0644',
  name           => '15-default-ssl.conf',
  notify         => 'Class[Apache::Service]',
  order          => 'numeric',
  owner          => 'root',
  path           => '/etc/apache2/sites-available/15-default-ssl.conf',
  replace        => 'true',
  require        => 'Package[httpd]',
  warn           => 'false',
}

concat { '15-default.conf':
  ensure         => 'absent',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'root',
  mode           => '0644',
  name           => '15-default.conf',
  notify         => 'Class[Apache::Service]',
  order          => 'numeric',
  owner          => 'root',
  path           => '/etc/apache2/sites-available/15-default.conf',
  replace        => 'true',
  require        => 'Package[httpd]',
  warn           => 'false',
}

concat { 'horizon_ssl_vhost.conf':
  ensure         => 'absent',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'root',
  mode           => '0644',
  name           => 'horizon_ssl_vhost.conf',
  notify         => 'Class[Apache::Service]',
  order          => 'numeric',
  owner          => 'root',
  path           => '/etc/apache2/sites-available/horizon_ssl_vhost.conf',
  replace        => 'true',
  require        => 'Package[httpd]',
  warn           => 'false',
}

concat { 'horizon_vhost.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'root',
  mode           => '0644',
  name           => 'horizon_vhost.conf',
  notify         => 'Class[Apache::Service]',
  order          => 'numeric',
  owner          => 'root',
  path           => '/etc/apache2/sites-available/horizon_vhost.conf',
  replace        => 'true',
  require        => 'Package[httpd]',
  warn           => 'false',
}

exec { 'chown_dashboard':
  command     => 'chown -R www-data:www-data /usr/share/openstack-dashboard/',
  path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  provider    => 'shell',
  refreshonly => 'true',
}

exec { 'concat_/etc/apache2/ports.conf':
  alias     => 'concat_/tmp//_etc_apache2_ports.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_apache2_ports.conf/fragments.concat.out" -d "/tmp//_etc_apache2_ports.conf"',
  notify    => 'File[/etc/apache2/ports.conf]',
  require   => ['File[/tmp//_etc_apache2_ports.conf]', 'File[/tmp//_etc_apache2_ports.conf/fragments]', 'File[/tmp//_etc_apache2_ports.conf/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_apache2_ports.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_apache2_ports.conf/fragments.concat.out" -d "/tmp//_etc_apache2_ports.conf" -t',
}

exec { 'concat_/etc/openstack-dashboard/local_settings.py':
  alias     => 'concat_/tmp//_etc_openstack-dashboard_local_settings.py',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_openstack-dashboard_local_settings.py/fragments.concat.out" -d "/tmp//_etc_openstack-dashboard_local_settings.py"',
  notify    => 'File[/etc/openstack-dashboard/local_settings.py]',
  require   => ['File[/tmp//_etc_openstack-dashboard_local_settings.py]', 'File[/tmp//_etc_openstack-dashboard_local_settings.py/fragments]', 'File[/tmp//_etc_openstack-dashboard_local_settings.py/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_openstack-dashboard_local_settings.py]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_openstack-dashboard_local_settings.py/fragments.concat.out" -d "/tmp//_etc_openstack-dashboard_local_settings.py" -t',
}

exec { 'concat_15-default-ssl.conf':
  alias   => 'concat_/tmp//15-default-ssl.conf',
  command => 'true',
  path    => '/bin:/usr/bin',
  unless  => 'true',
}

exec { 'concat_15-default.conf':
  alias   => 'concat_/tmp//15-default.conf',
  command => 'true',
  path    => '/bin:/usr/bin',
  unless  => 'true',
}

exec { 'concat_horizon_ssl_vhost.conf':
  alias   => 'concat_/tmp//horizon_ssl_vhost.conf',
  command => 'true',
  path    => '/bin:/usr/bin',
  unless  => 'true',
}

exec { 'concat_horizon_vhost.conf':
  alias     => 'concat_/tmp//horizon_vhost.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//horizon_vhost.conf/fragments.concat.out" -d "/tmp//horizon_vhost.conf" -n',
  notify    => 'File[horizon_vhost.conf]',
  require   => ['File[/tmp//horizon_vhost.conf]', 'File[/tmp//horizon_vhost.conf/fragments]', 'File[/tmp//horizon_vhost.conf/fragments.concat]'],
  subscribe => 'File[/tmp//horizon_vhost.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//horizon_vhost.conf/fragments.concat.out" -d "/tmp//horizon_vhost.conf" -n -t',
}

exec { 'mkdir /etc/apache2/conf.d':
  command => 'mkdir /etc/apache2/conf.d',
  creates => '/etc/apache2/conf.d',
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  require => 'Package[httpd]',
}

exec { 'mkdir /etc/apache2/mods-available':
  command => 'mkdir /etc/apache2/mods-available',
  creates => '/etc/apache2/mods-available',
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  require => 'Package[httpd]',
}

exec { 'mkdir /etc/apache2/mods-enabled':
  command => 'mkdir /etc/apache2/mods-enabled',
  creates => '/etc/apache2/mods-enabled',
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  require => 'Package[httpd]',
}

exec { 'mkdir /etc/apache2/sites-available':
  command => 'mkdir /etc/apache2/sites-available',
  creates => '/etc/apache2/sites-available',
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  require => 'Package[httpd]',
}

exec { 'mkdir /etc/apache2/sites-enabled':
  command => 'mkdir /etc/apache2/sites-enabled',
  creates => '/etc/apache2/sites-enabled',
  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  require => 'Package[httpd]',
}

exec { 'refresh_horizon_django_cache':
  command     => '/usr/share/openstack-dashboard/manage.py collectstatic --noinput --clear && /usr/share/openstack-dashboard/manage.py compress --force',
  notify      => 'Exec[chown_dashboard]',
  refreshonly => 'true',
  require     => ['Package[python-lesscpy]', 'Package[horizon]'],
}

file { '/etc/apache2/apache2.conf':
  ensure  => 'file',
  content => '# Security
ServerTokens Prod
ServerSignature Off
TraceEnable Off

ServerName "node-125"
ServerRoot "/etc/apache2"
PidFile ${APACHE_PID_FILE}
Timeout 120
KeepAlive Off
MaxKeepAliveRequests 100
KeepAliveTimeout 15

User www-data
Group www-data

AccessFileName .htaccess
<FilesMatch "^\.ht">
    Require all denied
</FilesMatch>

<Directory />
  Options FollowSymLinks
  AllowOverride None
</Directory>


HostnameLookups Off
ErrorLog "/var/log/apache2/error.log"
LogLevel warn
EnableSendfile On

#Listen 80


Include "/etc/apache2/mods-enabled/*.load"
Include "/etc/apache2/mods-enabled/*.conf"
Include "/etc/apache2/ports.conf"

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %b" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent

IncludeOptional "/etc/apache2/conf.d/*.conf"
IncludeOptional "/etc/apache2/sites-enabled/*"

',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/apache2.conf',
  require => 'Package[httpd]',
}

file { '/etc/apache2/conf-available/openstack-dashboard.conf':
  ensure  => 'present',
  content => '#
# This file has been cleaned by Puppet.
#
# OpenStack Horizon configuration has been moved to:
# - false-horizon_vhost.conf
# - false-horizon_ssl_vhost.conf
#',
  path    => '/etc/apache2/conf-available/openstack-dashboard.conf',
  require => 'Package[horizon]',
}

file { '/etc/apache2/conf.d':
  ensure  => 'directory',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/conf.d',
  purge   => 'false',
  recurse => 'true',
  require => 'Package[httpd]',
}

file { '/etc/apache2/mods-available':
  ensure  => 'directory',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available',
  purge   => 'false',
  recurse => 'true',
  require => 'Package[httpd]',
}

file { '/etc/apache2/mods-enabled':
  ensure  => 'directory',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-enabled',
  purge   => 'false',
  recurse => 'true',
  require => 'Package[httpd]',
}

file { '/etc/apache2/ports.conf':
  ensure  => 'present',
  alias   => 'concat_/etc/apache2/ports.conf',
  backup  => 'puppet',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/apache2/ports.conf',
  replace => 'true',
  source  => '/tmp//_etc_apache2_ports.conf/fragments.concat.out',
}

file { '/etc/apache2/sites-available/15-default-ssl.conf':
  ensure => 'absent',
  backup => 'puppet',
  path   => '/etc/apache2/sites-available/15-default-ssl.conf',
}

file { '/etc/apache2/sites-available/15-default.conf':
  ensure => 'absent',
  backup => 'puppet',
  path   => '/etc/apache2/sites-available/15-default.conf',
}

file { '/etc/apache2/sites-available/horizon_ssl_vhost.conf':
  ensure => 'absent',
  backup => 'puppet',
  path   => '/etc/apache2/sites-available/horizon_ssl_vhost.conf',
}

file { '/etc/apache2/sites-available':
  ensure  => 'directory',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/sites-available',
  purge   => 'false',
  recurse => 'true',
  require => 'Package[httpd]',
}

file { '/etc/apache2/sites-enabled':
  ensure  => 'directory',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/sites-enabled',
  purge   => 'false',
  recurse => 'true',
  require => 'Package[httpd]',
}

file { '/etc/logrotate.d/apache2':
  ensure  => 'file',
  content => '# This file managed via puppet
/var/log/apache2/*.log {
    weekly
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
       if /etc/init.d/apache2 status > /dev/null ; then \
           (/usr/sbin/apachectl graceful) || (/usr/sbin/apachectl restart)
       fi;
    endscript
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
            run-parts /etc/logrotate.d/httpd-prerotate; \
        fi; \
    endscript
}
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/logrotate.d/apache2',
  require => 'Package[httpd]',
}

file { '/etc/logrotate.d/httpd-prerotate/apache2':
  ensure  => 'file',
  content => '#!/bin/sh
# This is a prerotate script for apache2 that will add a delay to the log
# rotation to spread out the apache2 restarts. The goal of this script is to
# stager the apache restarts to prevent all services from being down at the
# same time. LP#1491576

sleep 0
',
  group   => 'root',
  mode    => '0755',
  owner   => 'root',
  path    => '/etc/logrotate.d/httpd-prerotate/apache2',
}

file { '/etc/logrotate.d/httpd-prerotate':
  ensure => 'directory',
  group  => 'root',
  mode   => '0755',
  owner  => 'root',
  path   => '/etc/logrotate.d/httpd-prerotate',
}

file { '/etc/openstack-dashboard/local_settings.py':
  ensure  => 'present',
  alias   => 'concat_/etc/openstack-dashboard/local_settings.py',
  backup  => 'puppet',
  mode    => '0644',
  notify  => 'Service[apache2]',
  path    => '/etc/openstack-dashboard/local_settings.py',
  replace => 'true',
  source  => '/tmp//_etc_openstack-dashboard_local_settings.py/fragments.concat.out',
}

file { '/tmp//15-default-ssl.conf/fragments.concat.out':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//15-default-ssl.conf/fragments.concat.out',
}

file { '/tmp//15-default-ssl.conf/fragments.concat':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//15-default-ssl.conf/fragments.concat',
}

file { '/tmp//15-default-ssl.conf/fragments/0_default-ssl-apache-header':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-apache-header',
  backup  => 'puppet',
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost *:443>
  ServerName default-ssl
  ServerAdmin root@localhost
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/0_default-ssl-apache-header',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments/100_default-ssl-access_log':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-access_log',
  backup  => 'puppet',
  content => '  CustomLog "/var/log/apache2/ssl_access.log" combined 
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/100_default-ssl-access_log',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments/10_default-ssl-docroot':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-docroot',
  backup  => 'puppet',
  content => '
  ## Vhost docroot
  DocumentRoot "/var/www"
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/10_default-ssl-docroot',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments/180_default-ssl-scriptalias':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-scriptalias',
  backup  => 'puppet',
  content => '  ## Script alias directives
  ScriptAlias /cgi-bin "/usr/lib/cgi-bin"
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/180_default-ssl-scriptalias',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments/210_default-ssl-ssl':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-ssl',
  backup  => 'puppet',
  content => '
  ## SSL directives
  SSLEngine on
  SSLCertificateFile      "/etc/ssl/certs/ssl-cert-snakeoil.pem"
  SSLCertificateKeyFile   "/etc/ssl/private/ssl-cert-snakeoil.key"
  SSLCACertificatePath    "/etc/ssl/certs"
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/210_default-ssl-ssl',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments/60_default-ssl-directories':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-directories',
  backup  => 'puppet',
  content => '
  ## Directories, there should at least be a declaration for /var/www

  <Directory "/var/www">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Require all granted
  </Directory>
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/60_default-ssl-directories',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments/80_default-ssl-logging':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-logging',
  backup  => 'puppet',
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/default-ssl_error_ssl.log"
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/80_default-ssl-logging',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments/90_default-ssl-serversignature':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-serversignature',
  backup  => 'puppet',
  content => '  ServerSignature Off
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/90_default-ssl-serversignature',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments/999_default-ssl-file_footer':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-ssl-file_footer',
  backup  => 'puppet',
  content => '</VirtualHost>
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default-ssl.conf]',
  path    => '/tmp//15-default-ssl.conf/fragments/999_default-ssl-file_footer',
  replace => 'true',
}

file { '/tmp//15-default-ssl.conf/fragments':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//15-default-ssl.conf/fragments',
}

file { '/tmp//15-default-ssl.conf':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//15-default-ssl.conf',
}

file { '/tmp//15-default.conf/fragments.concat.out':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//15-default.conf/fragments.concat.out',
}

file { '/tmp//15-default.conf/fragments.concat':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//15-default.conf/fragments.concat',
}

file { '/tmp//15-default.conf/fragments/0_default-apache-header':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-apache-header',
  backup  => 'puppet',
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost *:80>
  ServerName default
  ServerAdmin root@localhost
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default.conf]',
  path    => '/tmp//15-default.conf/fragments/0_default-apache-header',
  replace => 'true',
}

file { '/tmp//15-default.conf/fragments/100_default-access_log':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-access_log',
  backup  => 'puppet',
  content => '  CustomLog "/var/log/apache2/access.log" combined 
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default.conf]',
  path    => '/tmp//15-default.conf/fragments/100_default-access_log',
  replace => 'true',
}

file { '/tmp//15-default.conf/fragments/10_default-docroot':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-docroot',
  backup  => 'puppet',
  content => '
  ## Vhost docroot
  DocumentRoot "/var/www"
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default.conf]',
  path    => '/tmp//15-default.conf/fragments/10_default-docroot',
  replace => 'true',
}

file { '/tmp//15-default.conf/fragments/180_default-scriptalias':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-scriptalias',
  backup  => 'puppet',
  content => '  ## Script alias directives
  ScriptAlias /cgi-bin "/usr/lib/cgi-bin"
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default.conf]',
  path    => '/tmp//15-default.conf/fragments/180_default-scriptalias',
  replace => 'true',
}

file { '/tmp//15-default.conf/fragments/60_default-directories':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-directories',
  backup  => 'puppet',
  content => '
  ## Directories, there should at least be a declaration for /var/www

  <Directory "/var/www">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Require all granted
  </Directory>
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default.conf]',
  path    => '/tmp//15-default.conf/fragments/60_default-directories',
  replace => 'true',
}

file { '/tmp//15-default.conf/fragments/80_default-logging':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-logging',
  backup  => 'puppet',
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/default_error.log"
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default.conf]',
  path    => '/tmp//15-default.conf/fragments/80_default-logging',
  replace => 'true',
}

file { '/tmp//15-default.conf/fragments/90_default-serversignature':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-serversignature',
  backup  => 'puppet',
  content => '  ServerSignature Off
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default.conf]',
  path    => '/tmp//15-default.conf/fragments/90_default-serversignature',
  replace => 'true',
}

file { '/tmp//15-default.conf/fragments/999_default-file_footer':
  ensure  => 'absent',
  alias   => 'concat_fragment_default-file_footer',
  backup  => 'puppet',
  content => '</VirtualHost>
',
  mode    => '0640',
  notify  => 'Exec[concat_15-default.conf]',
  path    => '/tmp//15-default.conf/fragments/999_default-file_footer',
  replace => 'true',
}

file { '/tmp//15-default.conf/fragments':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//15-default.conf/fragments',
}

file { '/tmp//15-default.conf':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//15-default.conf',
}

file { '/tmp//_etc_apache2_ports.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_apache2_ports.conf/fragments.concat.out',
}

file { '/tmp//_etc_apache2_ports.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_apache2_ports.conf/fragments.concat',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_Apache ports header':
  ensure  => 'file',
  alias   => 'concat_fragment_Apache ports header',
  backup  => 'puppet',
  content => '# ************************************
# Listen & NameVirtualHost resources in module puppetlabs-apache
# Managed by Puppet
# ************************************

',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_Apache ports header',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_Listen 35357':
  ensure  => 'file',
  alias   => 'concat_fragment_Listen 35357',
  backup  => 'puppet',
  content => 'Listen 35357
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_Listen 35357',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_Listen 5000':
  ensure  => 'file',
  alias   => 'concat_fragment_Listen 5000',
  backup  => 'puppet',
  content => 'Listen 5000
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_Listen 5000',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_Listen 80':
  ensure  => 'file',
  alias   => 'concat_fragment_Listen 80',
  backup  => 'puppet',
  content => 'Listen 80
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_Listen 80',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_Listen 8888':
  ensure  => 'file',
  alias   => 'concat_fragment_Listen 8888',
  backup  => 'puppet',
  content => 'Listen 8888
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_Listen 8888',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_35357':
  ensure  => 'file',
  alias   => 'concat_fragment_NameVirtualHost *:35357',
  backup  => 'puppet',
  content => 'NameVirtualHost *:35357
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_35357',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_5000':
  ensure  => 'file',
  alias   => 'concat_fragment_NameVirtualHost *:5000',
  backup  => 'puppet',
  content => 'NameVirtualHost *:5000
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_5000',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_80':
  ensure  => 'file',
  alias   => 'concat_fragment_NameVirtualHost *:80',
  backup  => 'puppet',
  content => 'NameVirtualHost *:80
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_80',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_8888':
  ensure  => 'file',
  alias   => 'concat_fragment_NameVirtualHost *:8888',
  backup  => 'puppet',
  content => 'NameVirtualHost *:8888
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments/10_NameVirtualHost *_8888',
  replace => 'true',
}

file { '/tmp//_etc_apache2_ports.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/apache2/ports.conf]',
  path    => '/tmp//_etc_apache2_ports.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_apache2_ports.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_apache2_ports.conf',
}

file { '/tmp//_etc_openstack-dashboard_local_settings.py/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_openstack-dashboard_local_settings.py/fragments.concat.out',
}

file { '/tmp//_etc_openstack-dashboard_local_settings.py/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//_etc_openstack-dashboard_local_settings.py/fragments.concat',
}

file { '/tmp//_etc_openstack-dashboard_local_settings.py/fragments/50_local_settings.py':
  ensure  => 'file',
  alias   => 'concat_fragment_local_settings.py',
  backup  => 'puppet',
  content => 'import os

from django.utils.translation import ugettext_lazy as _

from openstack_dashboard import exceptions

DEBUG = False
TEMPLATE_DEBUG = DEBUG

# WEBROOT is the location relative to Webserver root
# should end with a slash.
WEBROOT = '/horizon/'

# Required for Django 1.5.
# If horizon is running in production (DEBUG is False), set this
# with the list of host/domain names that the application can serve.
# For more information see:
# https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts
#ALLOWED_HOSTS = ['horizon.example.com', ]

ALLOWED_HOSTS = ['*', ]


# Set SSL proxy settings:
# For Django 1.4+ pass this header from the proxy after terminating the SSL,
# and don't forget to strip it from the client's request.
# For more information see:
# https://docs.djangoproject.com/en/1.4/ref/settings/#secure-proxy-ssl-header
# SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTOCOL', 'https')

# If Horizon is being served through SSL, then uncomment the following two
# settings to better secure the cookies from security exploits

#CSRF_COOKIE_SECURE = True
#SESSION_COOKIE_SECURE = True


# Overrides for OpenStack API versions. Use this setting to force the
# OpenStack dashboard to use a specfic API version for a given service API.
# NOTE: The version should be formatted as it appears in the URL for the
# service API. For example, The identity service APIs have inconsistent
# use of the decimal point, so valid options would be "2.0" or "3".
# OPENSTACK_API_VERSIONS = {
#     "identity": 3
# }



# Set this to True if running on multi-domain model. When this is enabled, it
# will require user to enter the Domain name in addition to username for login.
# OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False


# Overrides the default domain used when running on single-domain model
# with Keystone V3. All entities will be created in the default domain.
# OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'


# Set Console type:
# valid options would be "AUTO", "VNC" or "SPICE"
# CONSOLE_TYPE = "AUTO"

# Default OpenStack Dashboard configuration.
HORIZON_CONFIG = {
    'dashboards': ('project', 'admin', 'settings',),
    'default_dashboard': 'project',
    'user_home': 'openstack_dashboard.views.get_user_home',
    'ajax_queue_limit': 10,
    'auto_fade_alerts': {
        'delay': 3000,
        'fade_duration': 1500,
        'types': ['alert-success', 'alert-info']
    },
    'help_url': "http://docs.openstack.org",
    'exceptions': {'recoverable': exceptions.RECOVERABLE,
                   'not_found': exceptions.NOT_FOUND,
                   'unauthorized': exceptions.UNAUTHORIZED},
}

# Specify a regular expression to validate user passwords.
# HORIZON_CONFIG["password_validator"] = {
#     "regex": '.*',
#     "help_text": _("Your password does not meet the requirements.")
# }

# Disable simplified floating IP address management for deployments with
# multiple floating IP pools or complex network requirements.
# HORIZON_CONFIG["simple_ip_management"] = False

# Turn off browser autocompletion for the login form if so desired.
# HORIZON_CONFIG["password_autocomplete"] = "off"

LOCAL_PATH = os.path.dirname(os.path.abspath(__file__))

# Set custom secret key:
# You can either set it to a specific value or you can let horizion generate a
# default secret key that is unique on this machine, e.i. regardless of the
# amount of Python WSGI workers (if used behind Apache+mod_wsgi): However, there
# may be situations where you would want to set this explicitly, e.g. when
# multiple dashboard instances are distributed on different machines (usually
# behind a load-balancer). Either you have to make sure that a session gets all
# requests routed to the same dashboard instance or you set the same SECRET_KEY
# for all of them.
# from horizon.utils import secret_key
# SECRET_KEY = secret_key.generate_or_read_from_file(os.path.join(LOCAL_PATH, '.secret_key_store'))
SECRET_KEY = 'dummy_secret_key'

# We recommend you use memcached for development; otherwise after every reload
# of the django development server, you will have to login again. To use
# memcached set CACHES to something like
# CACHES = {
#    'default': {
#        'BACKEND' : 'django.core.cache.backends.memcached.MemcachedCache',
#        'LOCATION' : '127.0.0.1:11211',
#    }
#}

CACHES = {
    'default': {
    
        'OPTIONS': {
                'DEAD_RETRY': 1,
                'SERVER_RETRIES': 1,
                'SOCKET_TIMEOUT': 1,
        },
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
    
          
            
        'LOCATION': [ '192.168.0.3:11211', ],
          
    
    }
}


SESSION_ENGINE = "django.contrib.sessions.backends.cache"


# Send email to the console by default
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
# Or send them to /dev/null
#EMAIL_BACKEND = 'django.core.mail.backends.dummy.EmailBackend'

# Configure these for your outgoing email host
# EMAIL_HOST = 'smtp.my-company.com'
# EMAIL_PORT = 25
# EMAIL_HOST_USER = 'djangomail'
# EMAIL_HOST_PASSWORD = 'top-secret!'

# For multiple regions uncomment this configuration, and add (endpoint, title).

OPENSTACK_KEYSTONE_URL = "http://192.168.0.7:5000/v2.0"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"

# Disable SSL certificate checks (useful for self-signed certificates):
# OPENSTACK_SSL_NO_VERIFY = False

OPENSTACK_SSL_NO_VERIFY = True

# The CA certificate to use to verify SSL connections
# OPENSTACK_SSL_CACERT = '/path/to/cacert.pem'

# The OPENSTACK_KEYSTONE_BACKEND settings can be used to identify the
# capabilities of the auth backend for Keystone.
# If Keystone has been configured to use LDAP as the auth backend then set
# can_edit_user to False and name to 'ldap'.
#
# TODO(tres): Remove these once Keystone has an API to identify auth backend.
OPENSTACK_KEYSTONE_BACKEND = {
    'name': 'native',
    'can_edit_user': True,
    'can_edit_group': True,
    'can_edit_project': True,
    'can_edit_domain': True,
    'can_edit_role': True
}

# The OPENSTACK_HYPERVISOR_FEATURES settings can be used to enable optional
# services provided by hypervisors.
OPENSTACK_HYPERVISOR_FEATURES = {
    'can_set_mount_point': True,
    'can_set_password': False,
}

# The OPENSTACK_CINDER_FEATURES settings can be used to enable optional
# services provided by cinder that is not exposed by its extension API.
OPENSTACK_CINDER_FEATURES = {
    'enable_backup': False,
}

# The OPENSTACK_NEUTRON_NETWORK settings can be used to enable optional
# services provided by neutron. Options currenly available are load
# balancer service, security groups, quotas, VPN service.
# The profile_support option is used to detect if an externa lrouter can be
# configured via the dashboard. When using specific plugins the
# profile_support can be turned on if needed.
OPENSTACK_NEUTRON_NETWORK = {
    'enable_distributed_router': False,
    'enable_firewall': False,
    'enable_ha_router': False,
    'enable_lb': False,
    'enable_quotas': True,
    'enable_security_group': True,
    'enable_vpn': False,
    'profile_support': 'None',
}

# The OPENSTACK_IMAGE_BACKEND settings can be used to customize features
# in the OpenStack Dashboard related to the Image service, such as the list
# of supported image formats.
# OPENSTACK_IMAGE_BACKEND = {
#     'image_formats': [
#         ('', ''),
#         ('aki', _('AKI - Amazon Kernel Image')),
#         ('ami', _('AMI - Amazon Machine Image')),
#         ('ari', _('ARI - Amazon Ramdisk Image')),
#         ('iso', _('ISO - Optical Disk Image')),
#         ('qcow2', _('QCOW2 - QEMU Emulator')),
#         ('raw', _('Raw')),
#         ('vdi', _('VDI')),
#         ('vhd', _('VHD')),
#         ('vmdk', _('VMDK'))
#     ]
# }

# OPENSTACK_ENDPOINT_TYPE specifies the endpoint type to use for the endpoints
# in the Keystone service catalog. Use this setting when Horizon is running
# external to the OpenStack environment. The default is 'publicURL'.
#OPENSTACK_ENDPOINT_TYPE = "publicURL"


# SECONDARY_ENDPOINT_TYPE specifies the fallback endpoint type to use in the
# case that OPENSTACK_ENDPOINT_TYPE is not present in the endpoints
# in the Keystone service catalog. Use this setting when Horizon is running
# external to the OpenStack environment. The default is None.  This
# value should differ from OPENSTACK_ENDPOINT_TYPE if used.
#SECONDARY_ENDPOINT_TYPE = "publicURL"


# The number of objects (Swift containers/objects or images) to display
# on a single page before providing a paging element (a "more" link)
# to paginate results.
API_RESULT_LIMIT = 1000
API_RESULT_PAGE_SIZE = 20

# The timezone of the server. This should correspond with the timezone
# of your entire OpenStack installation, and hopefully be in UTC.
TIME_ZONE = "UTC"

# If you have external monitoring links, eg:


# When launching an instance, the menu of available flavors is
# sorted by RAM usage, ascending.  Provide a callback method here
# (and/or a flag for reverse sort) for the sorted() method if you'd
# like a different behaviour.  For more info, see
# http://docs.python.org/2/library/functions.html#sorted
# CREATE_INSTANCE_FLAVOR_SORT = {
#     'key': my_awesome_callback_method,
#     'reverse': False,
# }

# CUSTOM_THEME_PATH allows to set to the directory location for the
# theme (e.g., "static/themes/blue"). The path can either be
# relative to the openstack_dashboard directory or an absolute path
# to an accessible location on the file system.
# If not specified, the default CUSTOM_THEME_PATH is
# static/themes/default.


# The Horizon Policy Enforcement engine uses these values to load per service
# policy rule files. The content of these files should match the files the
# OpenStack services are using to determine role based access control in the
# target installation.

# Path to directory containing policy.json files

#POLICY_FILES_PATH = os.path.join(ROOT_PATH, "conf")

# Map of local copy of service policy files
#POLICY_FILES = {
#    'identity': 'keystone_policy.json',
#    'compute': 'nova_policy.json'
#}

# Trove user and database extension support. By default support for
# creating users and databases on database instances is turned on.
# To disable these extensions set the permission here to something
# unusable such as ["!"].
# TROVE_ADD_USER_PERMS = []
# TROVE_ADD_DATABASE_PERMS = []

LOGGING = {
    'version': 1,
    # When set to True this will disable all logging except
    # for loggers specified in this configuration dictionary. Note that
    # if nothing is specified here and disable_existing_loggers is True,
    # django.db.backends will still log unless it is disabled explicitly.
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '%(asctime)s %(process)d %(levelname)s %(name)s '
                      '%(message)s'
        },
        'normal': {
            'format': 'dashboard-%(name)s: %(levelname)s %(message)s'
        },
    },
    'handlers': {
        'null': {
            'level': 'DEBUG',
            'class': 'django.utils.log.NullHandler',
        },
        'console': {
            # Set the level to "DEBUG" for verbose output logging.
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/var/log/horizon/horizon.log',
            'formatter': 'verbose',
        },
        'syslog': {
            'level': 'INFO',
            'facility': 'local1',
            'class': 'logging.handlers.SysLogHandler',
            'address': '/dev/log',
            'formatter': 'normal',
        }
    },
    'loggers': {
        # Logging from django.db.backends is VERY verbose, send to null
        # by default.
        'django.db.backends': {
            'handlers': ['null'],
            'propagate': False,
        },
        'requests': {
            'handlers': ['null'],
            'propagate': False,
        },
        'horizon': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'openstack_dashboard': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'novaclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'cinderclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'keystoneclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'glanceclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'neutronclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'heatclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'ceilometerclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'troveclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'swiftclient': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'openstack_auth': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'nose.plugins.manager': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
        'django': {
            # 'handlers': ['console'],
            'handlers': ['file'],
            # 'level': 'DEBUG',
            'level': 'INFO',
            'propagate': False,
        },
    }
}

SECURITY_GROUP_RULES = {
    'all_tcp': {
        'name': 'ALL TCP',
        'ip_protocol': 'tcp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_udp': {
        'name': 'ALL UDP',
        'ip_protocol': 'udp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_icmp': {
        'name': 'ALL ICMP',
        'ip_protocol': 'icmp',
        'from_port': '-1',
        'to_port': '-1',
    },
    'ssh': {
        'name': 'SSH',
        'ip_protocol': 'tcp',
        'from_port': '22',
        'to_port': '22',
    },
    'smtp': {
        'name': 'SMTP',
        'ip_protocol': 'tcp',
        'from_port': '25',
        'to_port': '25',
    },
    'dns': {
        'name': 'DNS',
        'ip_protocol': 'tcp',
        'from_port': '53',
        'to_port': '53',
    },
    'http': {
        'name': 'HTTP',
        'ip_protocol': 'tcp',
        'from_port': '80',
        'to_port': '80',
    },
    'pop3': {
        'name': 'POP3',
        'ip_protocol': 'tcp',
        'from_port': '110',
        'to_port': '110',
    },
    'imap': {
        'name': 'IMAP',
        'ip_protocol': 'tcp',
        'from_port': '143',
        'to_port': '143',
    },
    'ldap': {
        'name': 'LDAP',
        'ip_protocol': 'tcp',
        'from_port': '389',
        'to_port': '389',
    },
    'https': {
        'name': 'HTTPS',
        'ip_protocol': 'tcp',
        'from_port': '443',
        'to_port': '443',
    },
    'smtps': {
        'name': 'SMTPS',
        'ip_protocol': 'tcp',
        'from_port': '465',
        'to_port': '465',
    },
    'imaps': {
        'name': 'IMAPS',
        'ip_protocol': 'tcp',
        'from_port': '993',
        'to_port': '993',
    },
    'pop3s': {
        'name': 'POP3S',
        'ip_protocol': 'tcp',
        'from_port': '995',
        'to_port': '995',
    },
    'ms_sql': {
        'name': 'MS SQL',
        'ip_protocol': 'tcp',
        'from_port': '1433',
        'to_port': '1433',
    },
    'mysql': {
        'name': 'MYSQL',
        'ip_protocol': 'tcp',
        'from_port': '3306',
        'to_port': '3306',
    },
    'rdp': {
        'name': 'RDP',
        'ip_protocol': 'tcp',
        'from_port': '3389',
        'to_port': '3389',
    },
}

LOGIN_URL = '/horizon/auth/login/'
LOGOUT_URL = '/horizon/auth/logout/'
LOGIN_REDIRECT_URL = '/horizon'

# The Ubuntu package includes pre-compressed JS and compiled CSS to allow
# offline compression by default.  To enable online compression, install
# the python-lesscpy package and disable the following option.
COMPRESS_OFFLINE = True

# For Glance image upload, Horizon uses the file upload support from Django
# so we add this option to change the directory where uploaded files are temporarily
# stored until they are loaded into Glance.
FILE_UPLOAD_TEMP_DIR = '/tmp'



# Horizon doesn't know status of nova quotas. As result user may change
# nova quotas in horizon UI, while actually they are turned off in nova. To avoid such
# confusion ENABLED_QUOTA_GROUPS option were added. LP: 1286099, 1332457
ENABLED_QUOTA_GROUPS = {

    'nova': False

}
',
  mode    => '0640',
  notify  => 'Exec[concat_/etc/openstack-dashboard/local_settings.py]',
  path    => '/tmp//_etc_openstack-dashboard_local_settings.py/fragments/50_local_settings.py',
  replace => 'true',
}

file { '/tmp//_etc_openstack-dashboard_local_settings.py/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_/etc/openstack-dashboard/local_settings.py]',
  path    => '/tmp//_etc_openstack-dashboard_local_settings.py/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//_etc_openstack-dashboard_local_settings.py':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//_etc_openstack-dashboard_local_settings.py',
}

file { '/tmp//bin/concatfragments.rb':
  ensure => 'file',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp//bin/concatfragments.rb',
  source => 'puppet:///modules/concat/concatfragments.rb',
}

file { '/tmp//bin':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp//bin',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments.concat.out':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//horizon_ssl_vhost.conf/fragments.concat.out',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments.concat':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//horizon_ssl_vhost.conf/fragments.concat',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/0_horizon_ssl_vhost-apache-header':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-apache-header',
  backup  => 'puppet',
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost 192.168.0.3:443>
  ServerName node-125.test.domain.local
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/0_horizon_ssl_vhost-apache-header',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/100_horizon_ssl_vhost-access_log':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-access_log',
  backup  => 'puppet',
  content => '  CustomLog "/var/log/apache2/horizon_ssl_access.log" combined 
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/100_horizon_ssl_vhost-access_log',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/10_horizon_ssl_vhost-docroot':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-docroot',
  backup  => 'puppet',
  content => '
  ## Vhost docroot
  DocumentRoot "/var/www/"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/10_horizon_ssl_vhost-docroot',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/160_horizon_ssl_vhost-redirect':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-redirect',
  backup  => 'puppet',
  content => '
  ## RedirectMatch rules
  RedirectMatch permanent  ^/$ /horizon
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/160_horizon_ssl_vhost-redirect',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/190_horizon_ssl_vhost-serveralias':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-serveralias',
  backup  => 'puppet',
  content => '
  ## Server aliases
  ServerAlias node-125.test.domain.local
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/190_horizon_ssl_vhost-serveralias',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/200_horizon_ssl_vhost-setenv':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-setenv',
  backup  => 'puppet',
  content => '  SetEnvIf X-Forwarded-Proto https HTTPS=1
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/200_horizon_ssl_vhost-setenv',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/20_horizon_ssl_vhost-aliases':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-aliases',
  backup  => 'puppet',
  content => '  ## Alias declarations for resources outside the DocumentRoot
  Alias /horizon/static "/usr/share/openstack-dashboard/static"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/20_horizon_ssl_vhost-aliases',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/210_horizon_ssl_vhost-ssl':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-ssl',
  backup  => 'puppet',
  content => '
  ## SSL directives
  SSLEngine on
  SSLCertificateFile      "/etc/ssl/certs/ssl-cert-snakeoil.pem"
  SSLCertificateKeyFile   "/etc/ssl/private/ssl-cert-snakeoil.key"
  SSLCACertificatePath    "/etc/ssl/certs"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/210_horizon_ssl_vhost-ssl',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/240_horizon_ssl_vhost-header':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-header',
  backup  => 'puppet',
  content => '
  ## Header rules
  ## as per http://httpd.apache.org/docs/2.2/mod/mod_headers.html#header
  Header set X-XSS-Protection "1; mode=block"
  Header set X-Content-Type-Options nosniff
  Header always append X-Frame-Options SAMEORIGIN
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/240_horizon_ssl_vhost-header',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/260_horizon_ssl_vhost-wsgi':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-wsgi',
  backup  => 'puppet',
  content => '  WSGIDaemonProcess horizon-ssl group=horizon processes=4 threads=15 user=horizon
  WSGIProcessGroup horizon-ssl
  WSGIScriptAlias /horizon "/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/260_horizon_ssl_vhost-wsgi',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/270_horizon_ssl_vhost-custom_fragment':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-custom_fragment',
  backup  => 'puppet',
  content => '
  ## Custom fragment

<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Order allow,deny
  Allow from all
</Directory>


',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/270_horizon_ssl_vhost-custom_fragment',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/60_horizon_ssl_vhost-directories':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-directories',
  backup  => 'puppet',
  content => '
  ## Directories, there should at least be a declaration for /var/www/

  <Directory "/var/www/">
    Options -Indexes
    AllowOverride None
    Require all granted
  </Directory>
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/60_horizon_ssl_vhost-directories',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/80_horizon_ssl_vhost-logging':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-logging',
  backup  => 'puppet',
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/horizon_ssl_error.log"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/80_horizon_ssl_vhost-logging',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/90_horizon_ssl_vhost-serversignature':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-serversignature',
  backup  => 'puppet',
  content => '  ServerSignature Off
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/90_horizon_ssl_vhost-serversignature',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments/999_horizon_ssl_vhost-file_footer':
  ensure  => 'absent',
  alias   => 'concat_fragment_horizon_ssl_vhost-file_footer',
  backup  => 'puppet',
  content => '</VirtualHost>
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_ssl_vhost.conf]',
  path    => '/tmp//horizon_ssl_vhost.conf/fragments/999_horizon_ssl_vhost-file_footer',
  replace => 'true',
}

file { '/tmp//horizon_ssl_vhost.conf/fragments':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//horizon_ssl_vhost.conf/fragments',
}

file { '/tmp//horizon_ssl_vhost.conf':
  ensure => 'absent',
  backup => 'puppet',
  force  => 'true',
  path   => '/tmp//horizon_ssl_vhost.conf',
}

file { '/tmp//horizon_vhost.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//horizon_vhost.conf/fragments.concat.out',
}

file { '/tmp//horizon_vhost.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//horizon_vhost.conf/fragments.concat',
}

file { '/tmp//horizon_vhost.conf/fragments/0_horizon_vhost-apache-header':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-apache-header',
  backup  => 'puppet',
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost 192.168.0.3:80>
  ServerName node-125.test.domain.local
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/0_horizon_vhost-apache-header',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/100_horizon_vhost-access_log':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-access_log',
  backup  => 'puppet',
  content => '  CustomLog "/var/log/apache2/horizon_access.log" combined 
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/100_horizon_vhost-access_log',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/10_horizon_vhost-docroot':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-docroot',
  backup  => 'puppet',
  content => '
  ## Vhost docroot
  DocumentRoot "/var/www/"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/10_horizon_vhost-docroot',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/160_horizon_vhost-redirect':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-redirect',
  backup  => 'puppet',
  content => '
  ## RedirectMatch rules
  RedirectMatch permanent  ^/$ /horizon
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/160_horizon_vhost-redirect',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/190_horizon_vhost-serveralias':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-serveralias',
  backup  => 'puppet',
  content => '
  ## Server aliases
  ServerAlias node-125.test.domain.local
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/190_horizon_vhost-serveralias',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/200_horizon_vhost-setenv':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-setenv',
  backup  => 'puppet',
  content => '  SetEnvIf X-Forwarded-Proto https HTTPS=1
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/200_horizon_vhost-setenv',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/20_horizon_vhost-aliases':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-aliases',
  backup  => 'puppet',
  content => '  ## Alias declarations for resources outside the DocumentRoot
  Alias /horizon/static "/usr/share/openstack-dashboard/static"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/20_horizon_vhost-aliases',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/240_horizon_vhost-header':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-header',
  backup  => 'puppet',
  content => '
  ## Header rules
  ## as per http://httpd.apache.org/docs/2.2/mod/mod_headers.html#header
  Header set X-XSS-Protection "1; mode=block"
  Header set X-Content-Type-Options nosniff
  Header always append X-Frame-Options SAMEORIGIN
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/240_horizon_vhost-header',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/260_horizon_vhost-wsgi':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-wsgi',
  backup  => 'puppet',
  content => '  WSGIDaemonProcess horizon group=horizon processes=4 threads=15 user=horizon
  WSGIProcessGroup horizon
  WSGIScriptAlias /horizon "/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/260_horizon_vhost-wsgi',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/270_horizon_vhost-custom_fragment':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-custom_fragment',
  backup  => 'puppet',
  content => '
  ## Custom fragment

<Directory /usr/share/openstack-dashboard/openstack_dashboard/wsgi>
  Order allow,deny
  Allow from all
</Directory>


',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/270_horizon_vhost-custom_fragment',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/60_horizon_vhost-directories':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-directories',
  backup  => 'puppet',
  content => '
  ## Directories, there should at least be a declaration for /var/www/

  <Directory "/var/www/">
    Options -Indexes
    AllowOverride None
    Require all granted
  </Directory>
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/60_horizon_vhost-directories',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/80_horizon_vhost-logging':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-logging',
  backup  => 'puppet',
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/horizon_error.log"
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/80_horizon_vhost-logging',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/90_horizon_vhost-serversignature':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-serversignature',
  backup  => 'puppet',
  content => '  ServerSignature Off
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/90_horizon_vhost-serversignature',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments/999_horizon_vhost-file_footer':
  ensure  => 'file',
  alias   => 'concat_fragment_horizon_vhost-file_footer',
  backup  => 'puppet',
  content => '</VirtualHost>
',
  mode    => '0640',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments/999_horizon_vhost-file_footer',
  replace => 'true',
}

file { '/tmp//horizon_vhost.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_horizon_vhost.conf]',
  path    => '/tmp//horizon_vhost.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//horizon_vhost.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//horizon_vhost.conf',
}

file { '/tmp/':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp',
}

file { '/var/log/apache2':
  ensure  => 'directory',
  before  => 'Concat[15-default.conf]',
  path    => '/var/log/apache2',
  require => 'Package[httpd]',
}

file { '/var/log/horizon/horizon.log':
  ensure  => 'file',
  before  => 'Service[apache2]',
  group   => 'horizon',
  mode    => '0640',
  owner   => 'horizon',
  path    => '/var/log/horizon/horizon.log',
  require => ['File[/var/log/horizon]', 'Package[horizon]'],
}

file { '/var/log/horizon':
  ensure  => 'directory',
  before  => 'Service[apache2]',
  group   => 'horizon',
  mode    => '0751',
  owner   => 'horizon',
  path    => '/var/log/horizon',
  require => 'Package[horizon]',
}

file { '/var/www/':
  ensure  => 'directory',
  before  => 'Concat[horizon_vhost.conf]',
  group   => 'root',
  owner   => 'root',
  path    => '/var/www',
  require => 'Package[httpd]',
}

file { '15-default-ssl.conf symlink':
  ensure  => 'absent',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/sites-enabled/15-default-ssl.conf',
  require => 'Concat[15-default-ssl.conf]',
  target  => '/etc/apache2/sites-available/15-default-ssl.conf',
}

file { '15-default.conf symlink':
  ensure  => 'absent',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/sites-enabled/15-default.conf',
  require => 'Concat[15-default.conf]',
  target  => '/etc/apache2/sites-available/15-default.conf',
}

file { 'access_compat.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/access_compat.load',
  require => ['File[access_compat.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/access_compat.load',
}

file { 'access_compat.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule access_compat_module /usr/lib/apache2/modules/mod_access_compat.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/access_compat.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'alias.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/alias.conf',
  require => ['File[alias.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/alias.conf',
}

file { 'alias.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => '<IfModule alias_module>
Alias /icons/ "/usr/share/apache2/icons/"
<Directory "/usr/share/apache2/icons">
    Options Indexes MultiViews
    AllowOverride None
    Require all granted
</Directory>
</IfModule>
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/alias.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'alias.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/alias.load',
  require => ['File[alias.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/alias.load',
}

file { 'alias.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule alias_module /usr/lib/apache2/modules/mod_alias.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/alias.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'auth_basic.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/auth_basic.load',
  require => ['File[auth_basic.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/auth_basic.load',
}

file { 'auth_basic.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule auth_basic_module /usr/lib/apache2/modules/mod_auth_basic.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/auth_basic.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'authn_core.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/authn_core.load',
  require => ['File[authn_core.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/authn_core.load',
}

file { 'authn_core.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule authn_core_module /usr/lib/apache2/modules/mod_authn_core.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/authn_core.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'authn_file.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/authn_file.load',
  require => ['File[authn_file.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/authn_file.load',
}

file { 'authn_file.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule authn_file_module /usr/lib/apache2/modules/mod_authn_file.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/authn_file.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'authz_core.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/authz_core.load',
  require => ['File[authz_core.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/authz_core.load',
}

file { 'authz_core.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule authz_core_module /usr/lib/apache2/modules/mod_authz_core.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/authz_core.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'authz_groupfile.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/authz_groupfile.load',
  require => ['File[authz_groupfile.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/authz_groupfile.load',
}

file { 'authz_groupfile.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule authz_groupfile_module /usr/lib/apache2/modules/mod_authz_groupfile.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/authz_groupfile.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'authz_host.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/authz_host.load',
  require => ['File[authz_host.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/authz_host.load',
}

file { 'authz_host.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule authz_host_module /usr/lib/apache2/modules/mod_authz_host.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/authz_host.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'authz_user.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/authz_user.load',
  require => ['File[authz_user.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/authz_user.load',
}

file { 'authz_user.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule authz_user_module /usr/lib/apache2/modules/mod_authz_user.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/authz_user.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'autoindex.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/autoindex.conf',
  require => ['File[autoindex.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/autoindex.conf',
}

file { 'autoindex.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'IndexOptions FancyIndexing VersionSort HTMLTable NameWidth=* DescriptionWidth=* Charset=UTF-8
AddIconByEncoding (CMP,/icons/compressed.gif) x-compress x-gzip x-bzip2

AddIconByType (TXT,/icons/text.gif) text/*
AddIconByType (IMG,/icons/image2.gif) image/*
AddIconByType (SND,/icons/sound2.gif) audio/*
AddIconByType (VID,/icons/movie.gif) video/*

AddIcon /icons/binary.gif .bin .exe
AddIcon /icons/binhex.gif .hqx
AddIcon /icons/tar.gif .tar
AddIcon /icons/world2.gif .wrl .wrl.gz .vrml .vrm .iv
AddIcon /icons/compressed.gif .Z .z .tgz .gz .zip
AddIcon /icons/a.gif .ps .ai .eps
AddIcon /icons/layout.gif .html .shtml .htm .pdf
AddIcon /icons/text.gif .txt
AddIcon /icons/c.gif .c
AddIcon /icons/p.gif .pl .py
AddIcon /icons/f.gif .for
AddIcon /icons/dvi.gif .dvi
AddIcon /icons/uuencoded.gif .uu
AddIcon /icons/script.gif .conf .sh .shar .csh .ksh .tcl
AddIcon /icons/tex.gif .tex
AddIcon /icons/bomb.gif /core
AddIcon (SND,/icons/sound2.gif) .ogg
AddIcon (VID,/icons/movie.gif) .ogm

AddIcon /icons/back.gif ..
AddIcon /icons/hand.right.gif README
AddIcon /icons/folder.gif ^^DIRECTORY^^
AddIcon /icons/blank.gif ^^BLANKICON^^

AddIcon /icons/odf6odt-20x22.png .odt
AddIcon /icons/odf6ods-20x22.png .ods
AddIcon /icons/odf6odp-20x22.png .odp
AddIcon /icons/odf6odg-20x22.png .odg
AddIcon /icons/odf6odc-20x22.png .odc
AddIcon /icons/odf6odf-20x22.png .odf
AddIcon /icons/odf6odb-20x22.png .odb
AddIcon /icons/odf6odi-20x22.png .odi
AddIcon /icons/odf6odm-20x22.png .odm

AddIcon /icons/odf6ott-20x22.png .ott
AddIcon /icons/odf6ots-20x22.png .ots
AddIcon /icons/odf6otp-20x22.png .otp
AddIcon /icons/odf6otg-20x22.png .otg
AddIcon /icons/odf6otc-20x22.png .otc
AddIcon /icons/odf6otf-20x22.png .otf
AddIcon /icons/odf6oti-20x22.png .oti
AddIcon /icons/odf6oth-20x22.png .oth

DefaultIcon /icons/unknown.gif
ReadmeName README.html
HeaderName HEADER.html

IndexIgnore .??* *~ *# HEADER* README* RCS CVS *,v *,t
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/autoindex.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'autoindex.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/autoindex.load',
  require => ['File[autoindex.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/autoindex.load',
}

file { 'autoindex.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule autoindex_module /usr/lib/apache2/modules/mod_autoindex.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/autoindex.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'dav.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/dav.load',
  require => ['File[dav.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/dav.load',
}

file { 'dav.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule dav_module /usr/lib/apache2/modules/mod_dav.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/dav.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'dav_fs.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/dav_fs.conf',
  require => ['File[dav_fs.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/dav_fs.conf',
}

file { 'dav_fs.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'DAVLockDB "${APACHE_LOCK_DIR}/DAVLock"
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/dav_fs.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'dav_fs.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/dav_fs.load',
  require => ['File[dav_fs.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/dav_fs.load',
}

file { 'dav_fs.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule dav_fs_module /usr/lib/apache2/modules/mod_dav_fs.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/dav_fs.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'deflate.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/deflate.conf',
  require => ['File[deflate.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/deflate.conf',
}

file { 'deflate.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'AddOutputFilterByType DEFLATE application/rss+xml
AddOutputFilterByType DEFLATE application/x-javascript application/javascript application/ecmascript
AddOutputFilterByType DEFLATE text/css
AddOutputFilterByType DEFLATE text/html text/plain text/xml

DeflateFilterNote Input instream
DeflateFilterNote Output outstream
DeflateFilterNote Ratio ratio
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/deflate.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'deflate.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/deflate.load',
  require => ['File[deflate.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/deflate.load',
}

file { 'deflate.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule deflate_module /usr/lib/apache2/modules/mod_deflate.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/deflate.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'dir.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/dir.conf',
  require => ['File[dir.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/dir.conf',
}

file { 'dir.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'DirectoryIndex index.html index.html.var index.cgi index.pl index.php index.xhtml
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/dir.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'dir.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/dir.load',
  require => ['File[dir.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/dir.load',
}

file { 'dir.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule dir_module /usr/lib/apache2/modules/mod_dir.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/dir.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'env.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/env.load',
  require => ['File[env.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/env.load',
}

file { 'env.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule env_module /usr/lib/apache2/modules/mod_env.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/env.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'filter.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/filter.load',
  require => ['File[filter.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/filter.load',
}

file { 'filter.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule filter_module /usr/lib/apache2/modules/mod_filter.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/filter.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'headers.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/headers.load',
  require => ['File[headers.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/headers.load',
}

file { 'headers.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/headers.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'horizon_ssl_vhost.conf symlink':
  ensure  => 'absent',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/sites-enabled/horizon_ssl_vhost.conf',
  require => 'Concat[horizon_ssl_vhost.conf]',
  target  => '/etc/apache2/sites-available/horizon_ssl_vhost.conf',
}

file { 'horizon_vhost.conf symlink':
  ensure  => 'link',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/sites-enabled/horizon_vhost.conf',
  require => 'Concat[horizon_vhost.conf]',
  target  => '/etc/apache2/sites-available/horizon_vhost.conf',
}

file { 'horizon_vhost.conf':
  ensure  => 'present',
  alias   => 'concat_horizon_vhost.conf',
  backup  => 'puppet',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/apache2/sites-available/horizon_vhost.conf',
  replace => 'true',
  source  => '/tmp//horizon_vhost.conf/fragments.concat.out',
}

file { 'mime.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/mime.conf',
  require => ['File[mime.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/mime.conf',
}

file { 'mime.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'TypesConfig /etc/mime.types

AddType application/x-compress .Z
AddType application/x-gzip .gz .tgz
AddType application/x-bzip2 .bz2

AddLanguage ca .ca
AddLanguage cs .cz .cs
AddLanguage da .dk
AddLanguage de .de
AddLanguage el .el
AddLanguage en .en
AddLanguage eo .eo
AddLanguage es .es
AddLanguage et .et
AddLanguage fr .fr
AddLanguage he .he
AddLanguage hr .hr
AddLanguage it .it
AddLanguage ja .ja
AddLanguage ko .ko
AddLanguage ltz .ltz
AddLanguage nl .nl
AddLanguage nn .nn
AddLanguage no .no
AddLanguage pl .po
AddLanguage pt .pt
AddLanguage pt-BR .pt-br
AddLanguage ru .ru
AddLanguage sv .sv
AddLanguage zh-CN .zh-cn
AddLanguage zh-TW .zh-tw

AddHandler type-map var
AddType text/html .shtml
AddOutputFilter INCLUDES .shtml
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/mime.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'mime.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/mime.load',
  require => ['File[mime.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/mime.load',
}

file { 'mime.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule mime_module /usr/lib/apache2/modules/mod_mime.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/mime.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'negotiation.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/negotiation.conf',
  require => ['File[negotiation.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/negotiation.conf',
}

file { 'negotiation.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LanguagePriority en ca cs da de el eo es et fr he hr it ja ko ltz nl nn no pl pt pt-BR ru sv zh-CN zh-TW
ForceLanguagePriority Prefer Fallback
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/negotiation.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'negotiation.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/negotiation.load',
  require => ['File[negotiation.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/negotiation.load',
}

file { 'negotiation.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule negotiation_module /usr/lib/apache2/modules/mod_negotiation.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/negotiation.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'reqtimeout.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/reqtimeout.conf',
  require => ['File[reqtimeout.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/reqtimeout.conf',
}

file { 'reqtimeout.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'RequestReadTimeout header=20-40,minrate=500
RequestReadTimeout body=10,minrate=500
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/reqtimeout.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'reqtimeout.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/reqtimeout.load',
  require => ['File[reqtimeout.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/reqtimeout.load',
}

file { 'reqtimeout.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule reqtimeout_module /usr/lib/apache2/modules/mod_reqtimeout.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/reqtimeout.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'setenvif.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/setenvif.conf',
  require => ['File[setenvif.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/setenvif.conf',
}

file { 'setenvif.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => '#
# The following directives modify normal HTTP response behavior to
# handle known problems with browser implementations.
#
BrowserMatch "Mozilla/2" nokeepalive
BrowserMatch "MSIE 4\.0b2;" nokeepalive downgrade-1.0 force-response-1.0
BrowserMatch "RealPlayer 4\.0" force-response-1.0
BrowserMatch "Java/1\.0" force-response-1.0
BrowserMatch "JDK/1\.0" force-response-1.0

#
# The following directive disables redirects on non-GET requests for
# a directory that does not include the trailing slash.  This fixes a 
# problem with Microsoft WebFolders which does not appropriately handle 
# redirects for folders with DAV methods.
# Same deal with Apple's DAV filesystem and Gnome VFS support for DAV.
#
BrowserMatch "Microsoft Data Access Internet Publishing Provider" redirect-carefully
BrowserMatch "MS FrontPage" redirect-carefully
BrowserMatch "^WebDrive" redirect-carefully
BrowserMatch "^WebDAVFS/1.[0123]" redirect-carefully
BrowserMatch "^gnome-vfs/1.0" redirect-carefully
BrowserMatch "^gvfs/1" redirect-carefully
BrowserMatch "^XML Spy" redirect-carefully
BrowserMatch "^Dreamweaver-WebDAV-SCM1" redirect-carefully
BrowserMatch " Konqueror/4" redirect-carefully

<IfModule mod_ssl.c>
  BrowserMatch "MSIE [2-6]" \
    nokeepalive ssl-unclean-shutdown \
    downgrade-1.0 force-response-1.0
  # MSIE 7 and newer should be able to use keepalive
  BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
</IfModule>
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/setenvif.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'setenvif.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/setenvif.load',
  require => ['File[setenvif.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/setenvif.load',
}

file { 'setenvif.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule setenvif_module /usr/lib/apache2/modules/mod_setenvif.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/setenvif.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { 'wsgi.conf symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/wsgi.conf',
  require => ['File[wsgi.conf]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/wsgi.conf',
}

file { 'wsgi.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => '# The WSGI Apache module configuration file is being
# managed by Puppet an changes will be overwritten.
<IfModule mod_wsgi.c>
</IfModule>
',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available/wsgi.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { 'wsgi.load symlink':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/wsgi.load',
  require => ['File[wsgi.load]', 'Exec[mkdir /etc/apache2/mods-enabled]'],
  target  => '/etc/apache2/mods-available/wsgi.load',
}

file { 'wsgi.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/wsgi.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

group { 'www-data':
  ensure  => 'present',
  name    => 'www-data',
  require => 'Package[httpd]',
}

haproxy_backend_status { 'keystone-admin':
  count => '30',
  name  => 'keystone-2',
  step  => '3',
  url   => 'http://192.168.0.7:10000/;csv',
}

haproxy_backend_status { 'keystone-public':
  count => '30',
  name  => 'keystone-1',
  step  => '3',
  url   => 'http://192.168.0.7:10000/;csv',
}

osnailyfacter::apache::apache_port { '35357':
  name => '35357',
}

osnailyfacter::apache::apache_port { '5000':
  name => '5000',
}

osnailyfacter::apache::apache_port { '80':
  name => '80',
}

osnailyfacter::apache::apache_port { '8888':
  name => '8888',
}

package { 'horizon':
  ensure => 'installed',
  before => 'Package[apache2]',
  name   => 'openstack-dashboard',
  tag    => ['openstack', 'horizon-package'],
}

package { 'httpd':
  ensure => 'installed',
  name   => 'apache2',
  notify => 'Class[Apache::Service]',
}

package { 'libapache2-mod-wsgi':
  ensure  => 'present',
  before  => ['File[wsgi.load]', 'File[wsgi.conf]'],
  name    => 'libapache2-mod-wsgi',
  require => 'Package[httpd]',
}

package { 'mime-support':
  ensure => 'installed',
  before => 'File[mime.conf]',
  name   => 'mime-support',
}

package { 'python-lesscpy':
  ensure => 'installed',
  name   => 'python-lesscpy',
}

service { 'httpd':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  name       => 'apache2',
  restart    => 'sleep 30 && apachectl graceful || apachectl restart',
}

stage { 'main':
  name => 'main',
}

user { 'www-data':
  ensure  => 'present',
  gid     => 'www-data',
  name    => 'www-data',
  require => 'Package[httpd]',
}

