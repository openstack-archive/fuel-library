anchor { 'keystone_started':
  name    => 'keystone_started',
  require => 'Service[keystone]',
}

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

apache::vhost { 'keystone_wsgi_admin':
  ensure                      => 'present',
  access_log                  => 'true',
  access_log_env_var          => 'false',
  access_log_file             => 'false',
  access_log_format           => '%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"',
  access_log_pipe             => 'false',
  access_log_syslog           => 'false',
  add_listen                  => 'true',
  additional_includes         => [],
  apache_version              => '2.4',
  block                       => [],
  custom_fragment             => 'LimitRequestFieldSize 81900',
  default_vhost               => 'false',
  directoryindex              => '',
  docroot                     => '/usr/lib/cgi-bin/keystone',
  docroot_group               => 'keystone',
  docroot_owner               => 'keystone',
  error_documents             => [],
  error_log                   => 'true',
  ip_based                    => 'false',
  logroot                     => '/var/log/apache2',
  logroot_ensure              => 'directory',
  manage_docroot              => 'true',
  name                        => 'keystone_wsgi_admin',
  no_proxy_uris               => [],
  no_proxy_uris_match         => [],
  options                     => ['Indexes', 'FollowSymLinks', 'MultiViews'],
  override                    => 'None',
  php_admin_flags             => {},
  php_admin_values            => {},
  php_flags                   => {},
  php_values                  => {},
  port                        => '35357',
  priority                    => '05',
  proxy_error_override        => 'false',
  proxy_preserve_host         => 'false',
  redirect_source             => '/',
  require                     => 'File[keystone_wsgi_admin]',
  scriptaliases               => [],
  serveraliases               => [],
  servername                  => 'node-3.test.domain.local',
  setenv                      => [],
  setenvif                    => [],
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
  wsgi_application_group      => '%{GLOBAL}',
  wsgi_daemon_process         => 'keystone_admin',
  wsgi_daemon_process_options => {'display-name' => 'keystone-admin', 'group' => 'keystone', 'processes' => '4', 'threads' => '3', 'user' => 'keystone'},
  wsgi_pass_authorization     => 'On',
  wsgi_process_group          => 'keystone_admin',
  wsgi_script_aliases         => {'/' => '/usr/lib/cgi-bin/keystone/admin'},
}

apache::vhost { 'keystone_wsgi_main':
  ensure                      => 'present',
  access_log                  => 'true',
  access_log_env_var          => 'false',
  access_log_file             => 'false',
  access_log_format           => '%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"',
  access_log_pipe             => 'false',
  access_log_syslog           => 'false',
  add_listen                  => 'true',
  additional_includes         => [],
  apache_version              => '2.4',
  block                       => [],
  custom_fragment             => 'LimitRequestFieldSize 81900',
  default_vhost               => 'false',
  directoryindex              => '',
  docroot                     => '/usr/lib/cgi-bin/keystone',
  docroot_group               => 'keystone',
  docroot_owner               => 'keystone',
  error_documents             => [],
  error_log                   => 'true',
  ip_based                    => 'false',
  logroot                     => '/var/log/apache2',
  logroot_ensure              => 'directory',
  manage_docroot              => 'true',
  name                        => 'keystone_wsgi_main',
  no_proxy_uris               => [],
  no_proxy_uris_match         => [],
  options                     => ['Indexes', 'FollowSymLinks', 'MultiViews'],
  override                    => 'None',
  php_admin_flags             => {},
  php_admin_values            => {},
  php_flags                   => {},
  php_values                  => {},
  port                        => '5000',
  priority                    => '05',
  proxy_error_override        => 'false',
  proxy_preserve_host         => 'false',
  redirect_source             => '/',
  require                     => 'File[keystone_wsgi_main]',
  scriptaliases               => [],
  serveraliases               => [],
  servername                  => 'node-3.test.domain.local',
  setenv                      => [],
  setenvif                    => [],
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
  wsgi_application_group      => '%{GLOBAL}',
  wsgi_daemon_process         => 'keystone_main',
  wsgi_daemon_process_options => {'display-name' => 'keystone-main', 'group' => 'keystone', 'processes' => '4', 'threads' => '3', 'user' => 'keystone'},
  wsgi_pass_authorization     => 'On',
  wsgi_process_group          => 'keystone_main',
  wsgi_script_aliases         => {'/' => '/usr/lib/cgi-bin/keystone/main'},
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
  servername             => 'node-3',
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

class { 'Keystone::Client':
  ensure => 'present',
  name   => 'Keystone::Client',
}

class { 'Keystone::Db::Sync':
  name   => 'Keystone::Db::Sync',
  notify => 'Service[keystone]',
}

class { 'Keystone::Endpoint':
  admin_url    => 'http://172.16.1.2:35357',
  internal_url => 'http://172.16.1.2:5000',
  name         => 'Keystone::Endpoint',
  public_url   => 'https://public.fuel.local:5000',
  region       => 'RegionOne',
  version      => 'v2.0',
}

class { 'Keystone::Params':
  name => 'Keystone::Params',
}

class { 'Keystone::Roles::Admin':
  admin                 => 'admin',
  admin_roles           => 'admin',
  admin_tenant          => 'admin',
  admin_tenant_desc     => 'admin tenant',
  before                => 'Class[Openstack::Auth_file]',
  configure_user        => 'true',
  configure_user_role   => 'true',
  email                 => 'admin@localhost',
  ignore_default_tenant => 'false',
  name                  => 'Keystone::Roles::Admin',
  password              => 'admin',
  service_tenant        => 'services',
  service_tenant_desc   => 'Tenant for the openstack services',
}

class { 'Keystone::Service':
  ensure         => 'stopped',
  admin_endpoint => 'http://localhost:35357/v2.0',
  delay          => '2',
  enable         => 'false',
  hasrestart     => 'true',
  hasstatus      => 'true',
  insecure       => 'false',
  name           => 'Keystone::Service',
  provider       => 'upstart',
  retries        => '10',
  service_name   => 'keystone',
  validate       => 'false',
}

class { 'Keystone::Wsgi::Apache':
  access_log_format       => '%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"',
  admin_path              => '/',
  admin_port              => '35357',
  name                    => 'Keystone::Wsgi::Apache',
  priority                => '05',
  public_path             => '/',
  public_port             => '5000',
  servername              => 'node-3.test.domain.local',
  ssl                     => 'false',
  threads                 => '3',
  vhost_custom_fragment   => 'LimitRequestFieldSize 81900',
  workers                 => '4',
  wsgi_application_group  => '%{GLOBAL}',
  wsgi_pass_authorization => 'On',
  wsgi_script_ensure      => 'file',
}

class { 'Keystone':
  admin_bind_host                    => '172.16.1.5',
  admin_endpoint                     => 'false',
  admin_port                         => '35357',
  admin_token                        => 'Ro9qKUKs',
  admin_workers                      => '4',
  cache_backend                      => 'keystone.cache.memcache_pool',
  cache_dir                          => '/var/cache/keystone',
  catalog_driver                     => 'false',
  catalog_template_file              => '/etc/keystone/default_catalog.templates',
  catalog_type                       => 'sql',
  client_package_ensure              => 'present',
  control_exchange                   => 'false',
  database_connection                => 'mysql://keystone:RGAv0zS2@172.16.1.2/keystone?read_timeout=60',
  database_idle_timeout              => '3600',
  debug                              => 'false',
  debug_cache_backend                => 'false',
  enable_fernet_setup                => 'false',
  enable_pki_setup                   => 'true',
  enable_ssl                         => 'false',
  enabled                            => 'false',
  fernet_key_repository              => '/etc/keystone/fernet-keys',
  kombu_ssl_version                  => 'TLSv1',
  log_dir                            => '/var/log/keystone',
  log_facility                       => 'LOG_USER',
  log_file                           => 'false',
  manage_service                     => 'true',
  memcache_dead_retry                => '60',
  memcache_pool_maxsize              => '1000',
  memcache_pool_unused_timeout       => '60',
  memcache_servers                   => ['172.16.1.6:11211', '172.16.1.3:11211', '172.16.1.5:11211'],
  memcache_socket_timeout            => '1',
  name                               => 'Keystone',
  notification_driver                => 'false',
  notification_topics                => 'false',
  package_ensure                     => 'present',
  public_bind_host                   => '172.16.1.5',
  public_endpoint                    => 'https://public.fuel.local:5000',
  public_port                        => '5000',
  public_workers                     => '4',
  rabbit_heartbeat_rate              => '2',
  rabbit_heartbeat_timeout_threshold => '0',
  rabbit_host                        => 'localhost',
  rabbit_hosts                       => ['172.16.1.5:5673', ' 172.16.1.6:5673', ' 172.16.1.3:5673'],
  rabbit_password                    => 'XrExAeLy',
  rabbit_port                        => '5672',
  rabbit_use_ssl                     => 'false',
  rabbit_userid                      => 'nova',
  rabbit_virtual_host                => '/',
  require                            => ['Class[Mysql::Bindings]', 'Class[Mysql::Bindings::Python]'],
  revoke_driver                      => 'keystone.contrib.revoke.backends.sql.Revoke',
  service_name                       => 'keystone',
  service_provider                   => 'upstart',
  signing_ca_certs                   => '/etc/keystone/ssl/certs/ca.pem',
  signing_ca_key                     => '/etc/keystone/ssl/private/cakey.pem',
  signing_cert_subject               => '/C=US/ST=Unset/L=Unset/O=Unset/CN=www.example.com',
  signing_certfile                   => '/etc/keystone/ssl/certs/signing_cert.pem',
  signing_key_size                   => '2048',
  signing_keyfile                    => '/etc/keystone/ssl/private/signing_key.pem',
  ssl_ca_certs                       => '/etc/keystone/ssl/certs/ca.pem',
  ssl_ca_key                         => '/etc/keystone/ssl/private/cakey.pem',
  ssl_cert_subject                   => '/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost',
  ssl_certfile                       => '/etc/keystone/ssl/certs/keystone.pem',
  ssl_keyfile                        => '/etc/keystone/ssl/private/keystonekey.pem',
  sync_db                            => 'true',
  token_caching                      => 'false',
  token_driver                       => 'keystone.token.persistence.backends.memcache_pool.Token',
  token_expiration                   => '3600',
  token_provider                     => 'keystone.token.providers.uuid.Provider',
  use_stderr                         => 'false',
  use_syslog                         => 'true',
  validate_auth_url                  => 'false',
  validate_insecure                  => 'false',
  validate_service                   => 'false',
  verbose                            => 'true',
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

class { 'Openstack::Auth_file':
  admin_password         => 'admin',
  admin_tenant           => 'admin',
  admin_user             => 'admin',
  cinder_endpoint_type   => 'internalURL',
  controller_node        => '172.16.1.2',
  glance_endpoint_type   => 'internalURL',
  keystone_endpoint_type => 'internalURL',
  murano_repo_url        => 'http://storage.apps.openstack.org/',
  name                   => 'Openstack::Auth_file',
  neutron_endpoint_type  => 'internalURL',
  nova_endpoint_type     => 'internalURL',
  os_endpoint_type       => 'internalURL',
  region_name            => 'RegionOne',
  use_no_cache           => 'true',
}

class { 'Openstack::Keystone':
  admin_address         => '172.16.1.2',
  admin_bind_host       => '172.16.1.5',
  admin_token           => 'Ro9qKUKs',
  admin_url             => 'http://172.16.1.2:35357',
  cache_backend         => 'keystone.cache.memcache_pool',
  ceilometer            => 'false',
  database_idle_timeout => '3600',
  db_host               => '172.16.1.2',
  db_name               => 'keystone',
  db_password           => 'RGAv0zS2',
  db_type               => 'mysql',
  db_user               => 'keystone',
  debug                 => 'false',
  enabled               => 'true',
  internal_address      => '172.16.1.2',
  internal_url          => 'http://172.16.1.2:5000',
  max_overflow          => '20',
  max_pool_size         => '20',
  max_retries           => '-1',
  memcache_pool_maxsize => '100',
  memcache_server_port  => '11211',
  memcache_servers      => ['172.16.1.6', '172.16.1.3', '172.16.1.5'],
  name                  => 'Openstack::Keystone',
  package_ensure        => 'present',
  public_address        => 'public.fuel.local',
  public_bind_host      => '172.16.1.5',
  public_hostname       => 'public.fuel.local',
  public_ssl            => 'true',
  public_url            => 'https://public.fuel.local:5000',
  rabbit_hosts          => ['172.16.1.5:5673', ' 172.16.1.6:5673', ' 172.16.1.3:5673'],
  rabbit_password       => 'XrExAeLy',
  rabbit_userid         => 'nova',
  rabbit_virtual_host   => '/',
  region                => 'RegionOne',
  revoke_driver         => 'keystone.contrib.revoke.backends.sql.Revoke',
  service_workers       => '4',
  syslog_log_facility   => 'LOG_LOCAL7',
  token_caching         => 'false',
  use_stderr            => 'false',
  use_syslog            => 'true',
  verbose               => 'true',
}

class { 'Openstacklib::Openstackclient':
  name           => 'Openstacklib::Openstackclient',
  package_ensure => 'present',
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

concat::fragment { 'keystone_wsgi_admin-access_log':
  content => '  CustomLog "/var/log/apache2/keystone_wsgi_admin_access.log" "%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"" 
',
  name    => 'keystone_wsgi_admin-access_log',
  order   => '100',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_admin-apache-header':
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost *:35357>
  ServerName node-3.test.domain.local
',
  name    => 'keystone_wsgi_admin-apache-header',
  order   => '0',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_admin-custom_fragment':
  content => '
  ## Custom fragment
LimitRequestFieldSize 81900
',
  name    => 'keystone_wsgi_admin-custom_fragment',
  order   => '270',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_admin-directories':
  content => '
  ## Directories, there should at least be a declaration for /usr/lib/cgi-bin/keystone

  <Directory "/usr/lib/cgi-bin/keystone">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Require all granted
  </Directory>
',
  name    => 'keystone_wsgi_admin-directories',
  order   => '60',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_admin-docroot':
  content => '
  ## Vhost docroot
  DocumentRoot "/usr/lib/cgi-bin/keystone"
',
  name    => 'keystone_wsgi_admin-docroot',
  order   => '10',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_admin-file_footer':
  content => '</VirtualHost>
',
  name    => 'keystone_wsgi_admin-file_footer',
  order   => '999',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_admin-logging':
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/keystone_wsgi_admin_error.log"
',
  name    => 'keystone_wsgi_admin-logging',
  order   => '80',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_admin-serversignature':
  content => '  ServerSignature Off
',
  name    => 'keystone_wsgi_admin-serversignature',
  order   => '90',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_admin-wsgi':
  content => '  WSGIApplicationGroup %{GLOBAL}
  WSGIDaemonProcess keystone_admin display-name=keystone-admin group=keystone processes=4 threads=3 user=keystone
  WSGIProcessGroup keystone_admin
  WSGIScriptAlias / "/usr/lib/cgi-bin/keystone/admin"
  WSGIPassAuthorization On
',
  name    => 'keystone_wsgi_admin-wsgi',
  order   => '260',
  target  => '05-keystone_wsgi_admin.conf',
}

concat::fragment { 'keystone_wsgi_main-access_log':
  content => '  CustomLog "/var/log/apache2/keystone_wsgi_main_access.log" "%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"" 
',
  name    => 'keystone_wsgi_main-access_log',
  order   => '100',
  target  => '05-keystone_wsgi_main.conf',
}

concat::fragment { 'keystone_wsgi_main-apache-header':
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost *:5000>
  ServerName node-3.test.domain.local
',
  name    => 'keystone_wsgi_main-apache-header',
  order   => '0',
  target  => '05-keystone_wsgi_main.conf',
}

concat::fragment { 'keystone_wsgi_main-custom_fragment':
  content => '
  ## Custom fragment
LimitRequestFieldSize 81900
',
  name    => 'keystone_wsgi_main-custom_fragment',
  order   => '270',
  target  => '05-keystone_wsgi_main.conf',
}

concat::fragment { 'keystone_wsgi_main-directories':
  content => '
  ## Directories, there should at least be a declaration for /usr/lib/cgi-bin/keystone

  <Directory "/usr/lib/cgi-bin/keystone">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Require all granted
  </Directory>
',
  name    => 'keystone_wsgi_main-directories',
  order   => '60',
  target  => '05-keystone_wsgi_main.conf',
}

concat::fragment { 'keystone_wsgi_main-docroot':
  content => '
  ## Vhost docroot
  DocumentRoot "/usr/lib/cgi-bin/keystone"
',
  name    => 'keystone_wsgi_main-docroot',
  order   => '10',
  target  => '05-keystone_wsgi_main.conf',
}

concat::fragment { 'keystone_wsgi_main-file_footer':
  content => '</VirtualHost>
',
  name    => 'keystone_wsgi_main-file_footer',
  order   => '999',
  target  => '05-keystone_wsgi_main.conf',
}

concat::fragment { 'keystone_wsgi_main-logging':
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/keystone_wsgi_main_error.log"
',
  name    => 'keystone_wsgi_main-logging',
  order   => '80',
  target  => '05-keystone_wsgi_main.conf',
}

concat::fragment { 'keystone_wsgi_main-serversignature':
  content => '  ServerSignature Off
',
  name    => 'keystone_wsgi_main-serversignature',
  order   => '90',
  target  => '05-keystone_wsgi_main.conf',
}

concat::fragment { 'keystone_wsgi_main-wsgi':
  content => '  WSGIApplicationGroup %{GLOBAL}
  WSGIDaemonProcess keystone_main display-name=keystone-main group=keystone processes=4 threads=3 user=keystone
  WSGIProcessGroup keystone_main
  WSGIScriptAlias / "/usr/lib/cgi-bin/keystone/main"
  WSGIPassAuthorization On
',
  name    => 'keystone_wsgi_main-wsgi',
  order   => '260',
  target  => '05-keystone_wsgi_main.conf',
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

concat { '05-keystone_wsgi_admin.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'root',
  mode           => '0644',
  name           => '05-keystone_wsgi_admin.conf',
  notify         => 'Class[Apache::Service]',
  order          => 'numeric',
  owner          => 'root',
  path           => '/etc/apache2/sites-available/05-keystone_wsgi_admin.conf',
  replace        => 'true',
  require        => 'Package[httpd]',
  warn           => 'false',
}

concat { '05-keystone_wsgi_main.conf':
  ensure         => 'present',
  backup         => 'puppet',
  ensure_newline => 'false',
  force          => 'false',
  group          => 'root',
  mode           => '0644',
  name           => '05-keystone_wsgi_main.conf',
  notify         => 'Class[Apache::Service]',
  order          => 'numeric',
  owner          => 'root',
  path           => '/etc/apache2/sites-available/05-keystone_wsgi_main.conf',
  replace        => 'true',
  require        => 'Package[httpd]',
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

exec { 'add_admin_token_auth_middleware':
  before  => 'Exec[keystone-manage db_sync]',
  command => 'sed -i 's/\( token_auth \)/\1admin_token_auth /' /etc/keystone/keystone-paste.ini',
  path    => ['/bin', '/usr/bin'],
  require => 'Package[keystone]',
  unless  => 'fgrep -q ' admin_token_auth' /etc/keystone/keystone-paste.ini',
}

exec { 'concat_/etc/apache2/ports.conf':
  alias     => 'concat_/tmp//_etc_apache2_ports.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_apache2_ports.conf/fragments.concat.out" -d "/tmp//_etc_apache2_ports.conf"',
  notify    => 'File[/etc/apache2/ports.conf]',
  require   => ['File[/tmp//_etc_apache2_ports.conf]', 'File[/tmp//_etc_apache2_ports.conf/fragments]', 'File[/tmp//_etc_apache2_ports.conf/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_apache2_ports.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_apache2_ports.conf/fragments.concat.out" -d "/tmp//_etc_apache2_ports.conf" -t',
}

exec { 'concat_05-keystone_wsgi_admin.conf':
  alias     => 'concat_/tmp//05-keystone_wsgi_admin.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//05-keystone_wsgi_admin.conf/fragments.concat.out" -d "/tmp//05-keystone_wsgi_admin.conf" -n',
  notify    => 'File[05-keystone_wsgi_admin.conf]',
  require   => ['File[/tmp//05-keystone_wsgi_admin.conf]', 'File[/tmp//05-keystone_wsgi_admin.conf/fragments]', 'File[/tmp//05-keystone_wsgi_admin.conf/fragments.concat]'],
  subscribe => 'File[/tmp//05-keystone_wsgi_admin.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//05-keystone_wsgi_admin.conf/fragments.concat.out" -d "/tmp//05-keystone_wsgi_admin.conf" -n -t',
}

exec { 'concat_05-keystone_wsgi_main.conf':
  alias     => 'concat_/tmp//05-keystone_wsgi_main.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//05-keystone_wsgi_main.conf/fragments.concat.out" -d "/tmp//05-keystone_wsgi_main.conf" -n',
  notify    => 'File[05-keystone_wsgi_main.conf]',
  require   => ['File[/tmp//05-keystone_wsgi_main.conf]', 'File[/tmp//05-keystone_wsgi_main.conf/fragments]', 'File[/tmp//05-keystone_wsgi_main.conf/fragments.concat]'],
  subscribe => 'File[/tmp//05-keystone_wsgi_main.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//05-keystone_wsgi_main.conf/fragments.concat.out" -d "/tmp//05-keystone_wsgi_main.conf" -n -t',
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

exec { 'keystone-manage db_sync':
  before      => ['Class[Keystone::Endpoint]', 'Exec[purge_openrc]'],
  command     => 'keystone-manage  db_sync',
  notify      => ['Service[keystone]', 'Exec[purge_openrc]'],
  path        => '/usr/bin',
  refreshonly => 'true',
  require     => 'User[keystone]',
  subscribe   => ['Package[keystone]', 'Keystone_config[database/connection]'],
  user        => 'keystone',
}

exec { 'keystone-manage pki_setup':
  command     => 'keystone-manage pki_setup',
  creates     => '/etc/keystone/ssl/private/signing_key.pem',
  notify      => 'Service[keystone]',
  path        => '/usr/bin',
  refreshonly => 'true',
  require     => 'User[keystone]',
  subscribe   => 'Package[keystone]',
  user        => 'keystone',
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

exec { 'purge_openrc':
  before  => 'Class[Keystone::Roles::Admin]',
  command => 'rm -f /root/openrc',
  onlyif  => 'test -f /root/openrc',
  path    => '/bin:/usr/bin:/sbin:/usr/sbin',
}

exec { 'remove_keystone_override':
  before  => ['Service[keystone]', 'Service[keystone]'],
  command => 'rm -f /etc/init/keystone.override',
  onlyif  => 'test -f /etc/init/keystone.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/apache2/apache2.conf':
  ensure  => 'file',
  content => '# Security
ServerTokens Prod
ServerSignature Off
TraceEnable Off

ServerName "node-3"
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

file { '/etc/keystone/keystone.conf':
  ensure  => 'present',
  group   => 'keystone',
  mode    => '0600',
  notify  => 'Service[keystone]',
  owner   => 'keystone',
  path    => '/etc/keystone/keystone.conf',
  require => 'Package[keystone]',
}

file { '/etc/keystone':
  ensure  => 'directory',
  group   => 'keystone',
  mode    => '0750',
  notify  => 'Service[keystone]',
  owner   => 'keystone',
  path    => '/etc/keystone',
  require => 'Package[keystone]',
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

sleep 120
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

file { '/root/openrc':
  content => '#!/bin/sh
export LC_ALL=C
export OS_NO_CACHE='true'
export OS_TENANT_NAME='admin'
export OS_PROJECT_NAME='admin'
export OS_USERNAME='admin'
export OS_PASSWORD='admin'
export OS_AUTH_URL='http://172.16.1.2:5000/v2.0/'
export OS_DEFAULT_DOMAIN='default'
export OS_AUTH_STRATEGY='keystone'
export OS_REGION_NAME='RegionOne'
export CINDER_ENDPOINT_TYPE='internalURL'
export GLANCE_ENDPOINT_TYPE='internalURL'
export KEYSTONE_ENDPOINT_TYPE='internalURL'
export NOVA_ENDPOINT_TYPE='internalURL'
export NEUTRON_ENDPOINT_TYPE='internalURL'
export OS_ENDPOINT_TYPE='internalURL'
export MURANO_REPO_URL='http://storage.apps.openstack.org/'
',
  group   => 'root',
  mode    => '0700',
  owner   => 'root',
  path    => '/root/openrc',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//05-keystone_wsgi_admin.conf/fragments.concat.out',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//05-keystone_wsgi_admin.conf/fragments.concat',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/0_keystone_wsgi_admin-apache-header':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-apache-header',
  backup  => 'puppet',
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost *:35357>
  ServerName node-3.test.domain.local
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/0_keystone_wsgi_admin-apache-header',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/100_keystone_wsgi_admin-access_log':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-access_log',
  backup  => 'puppet',
  content => '  CustomLog "/var/log/apache2/keystone_wsgi_admin_access.log" "%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"" 
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/100_keystone_wsgi_admin-access_log',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/10_keystone_wsgi_admin-docroot':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-docroot',
  backup  => 'puppet',
  content => '
  ## Vhost docroot
  DocumentRoot "/usr/lib/cgi-bin/keystone"
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/10_keystone_wsgi_admin-docroot',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/260_keystone_wsgi_admin-wsgi':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-wsgi',
  backup  => 'puppet',
  content => '  WSGIApplicationGroup %{GLOBAL}
  WSGIDaemonProcess keystone_admin display-name=keystone-admin group=keystone processes=4 threads=3 user=keystone
  WSGIProcessGroup keystone_admin
  WSGIScriptAlias / "/usr/lib/cgi-bin/keystone/admin"
  WSGIPassAuthorization On
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/260_keystone_wsgi_admin-wsgi',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/270_keystone_wsgi_admin-custom_fragment':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-custom_fragment',
  backup  => 'puppet',
  content => '
  ## Custom fragment
LimitRequestFieldSize 81900
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/270_keystone_wsgi_admin-custom_fragment',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/60_keystone_wsgi_admin-directories':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-directories',
  backup  => 'puppet',
  content => '
  ## Directories, there should at least be a declaration for /usr/lib/cgi-bin/keystone

  <Directory "/usr/lib/cgi-bin/keystone">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Require all granted
  </Directory>
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/60_keystone_wsgi_admin-directories',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/80_keystone_wsgi_admin-logging':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-logging',
  backup  => 'puppet',
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/keystone_wsgi_admin_error.log"
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/80_keystone_wsgi_admin-logging',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/90_keystone_wsgi_admin-serversignature':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-serversignature',
  backup  => 'puppet',
  content => '  ServerSignature Off
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/90_keystone_wsgi_admin-serversignature',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments/999_keystone_wsgi_admin-file_footer':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_admin-file_footer',
  backup  => 'puppet',
  content => '</VirtualHost>
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments/999_keystone_wsgi_admin-file_footer',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_05-keystone_wsgi_admin.conf]',
  path    => '/tmp//05-keystone_wsgi_admin.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//05-keystone_wsgi_admin.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//05-keystone_wsgi_admin.conf',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments.concat.out':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//05-keystone_wsgi_main.conf/fragments.concat.out',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments.concat':
  ensure => 'present',
  backup => 'puppet',
  mode   => '0640',
  path   => '/tmp//05-keystone_wsgi_main.conf/fragments.concat',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/0_keystone_wsgi_main-apache-header':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-apache-header',
  backup  => 'puppet',
  content => '# ************************************
# Vhost template in module puppetlabs-apache
# Managed by Puppet
# ************************************

<VirtualHost *:5000>
  ServerName node-3.test.domain.local
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/0_keystone_wsgi_main-apache-header',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/100_keystone_wsgi_main-access_log':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-access_log',
  backup  => 'puppet',
  content => '  CustomLog "/var/log/apache2/keystone_wsgi_main_access.log" "%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"" 
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/100_keystone_wsgi_main-access_log',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/10_keystone_wsgi_main-docroot':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-docroot',
  backup  => 'puppet',
  content => '
  ## Vhost docroot
  DocumentRoot "/usr/lib/cgi-bin/keystone"
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/10_keystone_wsgi_main-docroot',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/260_keystone_wsgi_main-wsgi':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-wsgi',
  backup  => 'puppet',
  content => '  WSGIApplicationGroup %{GLOBAL}
  WSGIDaemonProcess keystone_main display-name=keystone-main group=keystone processes=4 threads=3 user=keystone
  WSGIProcessGroup keystone_main
  WSGIScriptAlias / "/usr/lib/cgi-bin/keystone/main"
  WSGIPassAuthorization On
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/260_keystone_wsgi_main-wsgi',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/270_keystone_wsgi_main-custom_fragment':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-custom_fragment',
  backup  => 'puppet',
  content => '
  ## Custom fragment
LimitRequestFieldSize 81900
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/270_keystone_wsgi_main-custom_fragment',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/60_keystone_wsgi_main-directories':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-directories',
  backup  => 'puppet',
  content => '
  ## Directories, there should at least be a declaration for /usr/lib/cgi-bin/keystone

  <Directory "/usr/lib/cgi-bin/keystone">
    Options Indexes FollowSymLinks MultiViews
    AllowOverride None
    Require all granted
  </Directory>
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/60_keystone_wsgi_main-directories',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/80_keystone_wsgi_main-logging':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-logging',
  backup  => 'puppet',
  content => '
  ## Logging
  ErrorLog "/var/log/apache2/keystone_wsgi_main_error.log"
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/80_keystone_wsgi_main-logging',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/90_keystone_wsgi_main-serversignature':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-serversignature',
  backup  => 'puppet',
  content => '  ServerSignature Off
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/90_keystone_wsgi_main-serversignature',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments/999_keystone_wsgi_main-file_footer':
  ensure  => 'file',
  alias   => 'concat_fragment_keystone_wsgi_main-file_footer',
  backup  => 'puppet',
  content => '</VirtualHost>
',
  mode    => '0640',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments/999_keystone_wsgi_main-file_footer',
  replace => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf/fragments':
  ensure  => 'directory',
  backup  => 'puppet',
  force   => 'true',
  ignore  => ['.svn', '.git', '.gitignore'],
  mode    => '0750',
  notify  => 'Exec[concat_05-keystone_wsgi_main.conf]',
  path    => '/tmp//05-keystone_wsgi_main.conf/fragments',
  purge   => 'true',
  recurse => 'true',
}

file { '/tmp//05-keystone_wsgi_main.conf':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0750',
  path   => '/tmp//05-keystone_wsgi_main.conf',
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

file { '/tmp/':
  ensure => 'directory',
  backup => 'puppet',
  mode   => '0755',
  path   => '/tmp',
}

file { '/usr/lib/cgi-bin/keystone':
  ensure  => 'directory',
  group   => 'keystone',
  owner   => 'keystone',
  path    => '/usr/lib/cgi-bin/keystone',
  require => 'Package[httpd]',
}

file { '/var/cache/keystone':
  ensure => 'directory',
  path   => '/var/cache/keystone',
}

file { '/var/lib/keystone':
  ensure  => 'directory',
  group   => 'keystone',
  mode    => '0750',
  notify  => 'Service[keystone]',
  owner   => 'keystone',
  path    => '/var/lib/keystone',
  require => 'Package[keystone]',
}

file { '/var/log/apache2':
  ensure  => 'directory',
  before  => 'Concat[15-default.conf]',
  path    => '/var/log/apache2',
  require => 'Package[httpd]',
}

file { '/var/log/keystone':
  ensure  => 'directory',
  group   => 'keystone',
  mode    => '0750',
  notify  => 'Service[keystone]',
  owner   => 'keystone',
  path    => '/var/log/keystone',
  require => 'Package[keystone]',
}

file { '05-keystone_wsgi_admin.conf symlink':
  ensure  => 'link',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/sites-enabled/05-keystone_wsgi_admin.conf',
  require => 'Concat[05-keystone_wsgi_admin.conf]',
  target  => '/etc/apache2/sites-available/05-keystone_wsgi_admin.conf',
}

file { '05-keystone_wsgi_admin.conf':
  ensure  => 'present',
  alias   => 'concat_05-keystone_wsgi_admin.conf',
  backup  => 'puppet',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/apache2/sites-available/05-keystone_wsgi_admin.conf',
  replace => 'true',
  source  => '/tmp//05-keystone_wsgi_admin.conf/fragments.concat.out',
}

file { '05-keystone_wsgi_main.conf symlink':
  ensure  => 'link',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/sites-enabled/05-keystone_wsgi_main.conf',
  require => 'Concat[05-keystone_wsgi_main.conf]',
  target  => '/etc/apache2/sites-available/05-keystone_wsgi_main.conf',
}

file { '05-keystone_wsgi_main.conf':
  ensure  => 'present',
  alias   => 'concat_05-keystone_wsgi_main.conf',
  backup  => 'puppet',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/apache2/sites-available/05-keystone_wsgi_main.conf',
  replace => 'true',
  source  => '/tmp//05-keystone_wsgi_main.conf/fragments.concat.out',
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

file { 'create_keystone_override':
  ensure  => 'present',
  before  => ['Package[keystone]', 'Package[keystone]', 'Exec[remove_keystone_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/keystone.override',
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

file { 'keystone_wsgi_admin':
  ensure  => 'file',
  group   => 'keystone',
  mode    => '0644',
  owner   => 'keystone',
  path    => '/usr/lib/cgi-bin/keystone/admin',
  require => ['File[/usr/lib/cgi-bin/keystone]', 'Package[keystone]'],
  source  => '/usr/share/keystone/wsgi.py',
}

file { 'keystone_wsgi_main':
  ensure  => 'file',
  group   => 'keystone',
  mode    => '0644',
  owner   => 'keystone',
  path    => '/usr/lib/cgi-bin/keystone/main',
  require => ['File[/usr/lib/cgi-bin/keystone]', 'Package[keystone]'],
  source  => '/usr/share/keystone/wsgi.py',
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

group { 'keystone':
  ensure  => 'present',
  name    => 'keystone',
  require => 'Package[keystone]',
  system  => 'true',
}

group { 'www-data':
  ensure  => 'present',
  name    => 'www-data',
  require => 'Package[httpd]',
}

haproxy_backend_status { 'keystone-admin':
  before => ['Class[Keystone::Endpoint]', 'Class[Keystone::Roles::Admin]'],
  name   => 'keystone-2',
  url    => 'http://172.16.1.2:10000/;csv',
}

haproxy_backend_status { 'keystone-public':
  before => ['Class[Keystone::Endpoint]', 'Class[Keystone::Roles::Admin]'],
  name   => 'keystone-1',
  url    => 'http://172.16.1.2:10000/;csv',
}

keystone::resource::service_identity { 'keystone':
  admin_url             => 'http://172.16.1.2:35357/v2.0',
  auth_name             => 'keystone',
  configure_endpoint    => 'true',
  configure_service     => 'true',
  configure_user        => 'false',
  configure_user_role   => 'false',
  email                 => 'keystone@localhost',
  ignore_default_tenant => 'false',
  internal_url          => 'http://172.16.1.2:5000/v2.0',
  name                  => 'keystone',
  password              => 'false',
  public_url            => 'https://public.fuel.local:5000/v2.0',
  region                => 'RegionOne',
  roles                 => 'admin',
  service_description   => 'OpenStack Identity Service',
  service_type          => 'identity',
  tenant                => 'services',
}

keystone_config { 'DATABASE/max_overflow':
  name   => 'DATABASE/max_overflow',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '20',
}

keystone_config { 'DATABASE/max_pool_size':
  name   => 'DATABASE/max_pool_size',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '20',
}

keystone_config { 'DATABASE/max_retries':
  name   => 'DATABASE/max_retries',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '-1',
}

keystone_config { 'DEFAULT/admin_bind_host':
  name   => 'DEFAULT/admin_bind_host',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '172.16.1.5',
}

keystone_config { 'DEFAULT/admin_endpoint':
  ensure => 'absent',
  name   => 'DEFAULT/admin_endpoint',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'DEFAULT/admin_port':
  name   => 'DEFAULT/admin_port',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '35357',
}

keystone_config { 'DEFAULT/admin_token':
  name   => 'DEFAULT/admin_token',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  secret => 'true',
  value  => 'Ro9qKUKs',
}

keystone_config { 'DEFAULT/compute_port':
  ensure => 'absent',
  name   => 'DEFAULT/compute_port',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'DEFAULT/control_exchange':
  ensure => 'absent',
  name   => 'DEFAULT/control_exchange',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'DEFAULT/debug':
  name   => 'DEFAULT/debug',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'false',
}

keystone_config { 'DEFAULT/log_dir':
  name   => 'DEFAULT/log_dir',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/var/log/keystone',
}

keystone_config { 'DEFAULT/log_file':
  ensure => 'absent',
  name   => 'DEFAULT/log_file',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'DEFAULT/max_token_size':
  ensure => 'absent',
  name   => 'DEFAULT/max_token_size',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'DEFAULT/notification_driver':
  ensure => 'absent',
  name   => 'DEFAULT/notification_driver',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'DEFAULT/notification_format':
  ensure => 'absent',
  name   => 'DEFAULT/notification_format',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'DEFAULT/notification_topics':
  ensure => 'absent',
  name   => 'DEFAULT/notification_topics',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'DEFAULT/public_bind_host':
  name   => 'DEFAULT/public_bind_host',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '172.16.1.5',
}

keystone_config { 'DEFAULT/public_endpoint':
  name   => 'DEFAULT/public_endpoint',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'https://public.fuel.local:5000',
}

keystone_config { 'DEFAULT/public_port':
  name   => 'DEFAULT/public_port',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '5000',
}

keystone_config { 'DEFAULT/syslog_log_facility':
  name   => 'DEFAULT/syslog_log_facility',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'LOG_USER',
}

keystone_config { 'DEFAULT/use_stderr':
  name   => 'DEFAULT/use_stderr',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'false',
}

keystone_config { 'DEFAULT/use_syslog':
  name   => 'DEFAULT/use_syslog',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'true',
}

keystone_config { 'DEFAULT/use_syslog_rfc_format':
  name   => 'DEFAULT/use_syslog_rfc_format',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'true',
}

keystone_config { 'DEFAULT/verbose':
  name   => 'DEFAULT/verbose',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'true',
}

keystone_config { 'app:admin_service/paste.app_factory':
  name   => 'app:admin_service/paste.app_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.service:admin_app_factory',
}

keystone_config { 'app:admin_version_service/paste.app_factory':
  name   => 'app:admin_version_service/paste.app_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.service:admin_version_app_factory',
}

keystone_config { 'app:public_service/paste.app_factory':
  name   => 'app:public_service/paste.app_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.service:public_app_factory',
}

keystone_config { 'app:public_version_service/paste.app_factory':
  name   => 'app:public_version_service/paste.app_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.service:public_version_app_factory',
}

keystone_config { 'cache/backend':
  name   => 'cache/backend',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.cache.memcache_pool',
}

keystone_config { 'cache/backend_argument':
  ensure => 'absent',
  name   => 'cache/backend_argument',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'cache/debug_cache_backend':
  name   => 'cache/debug_cache_backend',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'false',
}

keystone_config { 'cache/enabled':
  name   => 'cache/enabled',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'true',
}

keystone_config { 'cache/memcache_dead_retry':
  name   => 'cache/memcache_dead_retry',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '60',
}

keystone_config { 'cache/memcache_pool_maxsize':
  name   => 'cache/memcache_pool_maxsize',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '1000',
}

keystone_config { 'cache/memcache_pool_unused_timeout':
  name   => 'cache/memcache_pool_unused_timeout',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '60',
}

keystone_config { 'cache/memcache_socket_timeout':
  name   => 'cache/memcache_socket_timeout',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '1',
}

keystone_config { 'catalog/driver':
  name   => 'catalog/driver',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.catalog.backends.sql.Catalog',
}

keystone_config { 'catalog/template_file':
  name   => 'catalog/template_file',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/etc/keystone/default_catalog.templates',
}

keystone_config { 'composite:admin//':
  name   => 'composite:admin//',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'admin_version_api',
}

keystone_config { 'composite:admin//v2.0':
  name   => 'composite:admin//v2.0',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'admin_api',
}

keystone_config { 'composite:admin/use':
  name   => 'composite:admin/use',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'egg:Paste#urlmap',
}

keystone_config { 'composite:main//':
  name   => 'composite:main//',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'public_version_api',
}

keystone_config { 'composite:main//v2.0':
  name   => 'composite:main//v2.0',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'public_api',
}

keystone_config { 'composite:main/use':
  name   => 'composite:main/use',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'egg:Paste#urlmap',
}

keystone_config { 'database/connection':
  name   => 'database/connection',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  secret => 'true',
  value  => 'mysql://keystone:RGAv0zS2@172.16.1.2/keystone?read_timeout=60',
}

keystone_config { 'database/idle_timeout':
  name   => 'database/idle_timeout',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '3600',
}

keystone_config { 'ec2/driver':
  name   => 'ec2/driver',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.contrib.ec2.backends.sql.Ec2',
}

keystone_config { 'eventlet_server/admin_workers':
  name   => 'eventlet_server/admin_workers',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '4',
}

keystone_config { 'eventlet_server/public_workers':
  name   => 'eventlet_server/public_workers',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '4',
}

keystone_config { 'fernet_tokens/key_repository':
  name   => 'fernet_tokens/key_repository',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/etc/keystone/fernet-keys',
}

keystone_config { 'fernet_tokens/max_active_keys':
  ensure => 'absent',
  name   => 'fernet_tokens/max_active_keys',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'filter:admin_token_auth/paste.filter_factory':
  name   => 'filter:admin_token_auth/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.middleware:AdminTokenAuthMiddleware.factory',
}

keystone_config { 'filter:crud_extension/paste.filter_factory':
  name   => 'filter:crud_extension/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.contrib.admin_crud:CrudExtension.factory',
}

keystone_config { 'filter:debug/paste.filter_factory':
  name   => 'filter:debug/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.common.wsgi:Debug.factory',
}

keystone_config { 'filter:ec2_extension/paste.filter_factory':
  name   => 'filter:ec2_extension/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.contrib.ec2:Ec2Extension.factory',
}

keystone_config { 'filter:json_body/paste.filter_factory':
  name   => 'filter:json_body/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.middleware:JsonBodyMiddleware.factory',
}

keystone_config { 'filter:s3_extension/paste.filter_factory':
  name   => 'filter:s3_extension/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.contrib.s3:S3Extension.factory',
}

keystone_config { 'filter:stats_monitoring/paste.filter_factory':
  name   => 'filter:stats_monitoring/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.contrib.stats:StatsMiddleware.factory',
}

keystone_config { 'filter:stats_reporting/paste.filter_factory':
  name   => 'filter:stats_reporting/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.contrib.stats:StatsExtension.factory',
}

keystone_config { 'filter:token_auth/paste.filter_factory':
  name   => 'filter:token_auth/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.middleware:TokenAuthMiddleware.factory',
}

keystone_config { 'filter:url_normalize/paste.filter_factory':
  name   => 'filter:url_normalize/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.middleware:NormalizingFilter.factory',
}

keystone_config { 'filter:user_crud_extension/paste.filter_factory':
  name   => 'filter:user_crud_extension/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.contrib.user_crud:CrudExtension.factory',
}

keystone_config { 'filter:xml_body/paste.filter_factory':
  name   => 'filter:xml_body/paste.filter_factory',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.middleware:XmlBodyMiddleware.factory',
}

keystone_config { 'identity/driver':
  name   => 'identity/driver',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.identity.backends.sql.Identity',
}

keystone_config { 'memcache/dead_retry':
  name   => 'memcache/dead_retry',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '60',
}

keystone_config { 'memcache/pool_maxsize':
  name   => 'memcache/pool_maxsize',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '1000',
}

keystone_config { 'memcache/pool_unused_timeout':
  name   => 'memcache/pool_unused_timeout',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '60',
}

keystone_config { 'memcache/servers':
  name   => 'memcache/servers',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '172.16.1.6:11211,172.16.1.3:11211,172.16.1.5:11211',
}

keystone_config { 'memcache/socket_timeout':
  name   => 'memcache/socket_timeout',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '1',
}

keystone_config { 'oslo_messaging_rabbit/heartbeat_rate':
  name   => 'oslo_messaging_rabbit/heartbeat_rate',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '2',
}

keystone_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold':
  name   => 'oslo_messaging_rabbit/heartbeat_timeout_threshold',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '0',
}

keystone_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_ca_certs',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'oslo_messaging_rabbit/kombu_ssl_certfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_certfile',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'oslo_messaging_rabbit/kombu_ssl_keyfile':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_keyfile',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'oslo_messaging_rabbit/kombu_ssl_version':
  ensure => 'absent',
  name   => 'oslo_messaging_rabbit/kombu_ssl_version',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'oslo_messaging_rabbit/rabbit_ha_queues':
  name   => 'oslo_messaging_rabbit/rabbit_ha_queues',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'true',
}

keystone_config { 'oslo_messaging_rabbit/rabbit_hosts':
  name   => 'oslo_messaging_rabbit/rabbit_hosts',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '172.16.1.5:5673, 172.16.1.6:5673, 172.16.1.3:5673',
}

keystone_config { 'oslo_messaging_rabbit/rabbit_password':
  name   => 'oslo_messaging_rabbit/rabbit_password',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  secret => 'true',
  value  => 'XrExAeLy',
}

keystone_config { 'oslo_messaging_rabbit/rabbit_use_ssl':
  name   => 'oslo_messaging_rabbit/rabbit_use_ssl',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'false',
}

keystone_config { 'oslo_messaging_rabbit/rabbit_userid':
  name   => 'oslo_messaging_rabbit/rabbit_userid',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'nova',
}

keystone_config { 'oslo_messaging_rabbit/rabbit_virtual_host':
  name   => 'oslo_messaging_rabbit/rabbit_virtual_host',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/',
}

keystone_config { 'paste_deploy/config_file':
  ensure => 'absent',
  name   => 'paste_deploy/config_file',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
}

keystone_config { 'pipeline:admin_api/pipeline':
  name   => 'pipeline:admin_api/pipeline',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug stats_reporting ec2_extension s3_extension crud_extension admin_service',
}

keystone_config { 'pipeline:admin_version_api/pipeline':
  name   => 'pipeline:admin_version_api/pipeline',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'stats_monitoring url_normalize xml_body admin_version_service',
}

keystone_config { 'pipeline:public_api/pipeline':
  name   => 'pipeline:public_api/pipeline',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'stats_monitoring url_normalize token_auth admin_token_auth xml_body json_body debug ec2_extension user_crud_extension public_service',
}

keystone_config { 'pipeline:public_version_api/pipeline':
  name   => 'pipeline:public_version_api/pipeline',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'stats_monitoring url_normalize xml_body public_version_service',
}

keystone_config { 'policy/driver':
  name   => 'policy/driver',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.policy.backends.sql.Policy',
}

keystone_config { 'revoke/driver':
  name   => 'revoke/driver',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.contrib.revoke.backends.sql.Revoke',
}

keystone_config { 'signing/ca_certs':
  name   => 'signing/ca_certs',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/etc/keystone/ssl/certs/ca.pem',
}

keystone_config { 'signing/ca_key':
  name   => 'signing/ca_key',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/etc/keystone/ssl/private/cakey.pem',
}

keystone_config { 'signing/cert_subject':
  name   => 'signing/cert_subject',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/C=US/ST=Unset/L=Unset/O=Unset/CN=www.example.com',
}

keystone_config { 'signing/certfile':
  name   => 'signing/certfile',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/etc/keystone/ssl/certs/signing_cert.pem',
}

keystone_config { 'signing/key_size':
  name   => 'signing/key_size',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '2048',
}

keystone_config { 'signing/keyfile':
  name   => 'signing/keyfile',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '/etc/keystone/ssl/private/signing_key.pem',
}

keystone_config { 'ssl/enable':
  name   => 'ssl/enable',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'false',
}

keystone_config { 'token/caching':
  name   => 'token/caching',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'false',
}

keystone_config { 'token/driver':
  name   => 'token/driver',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.token.persistence.backends.memcache_pool.Token',
}

keystone_config { 'token/expiration':
  name   => 'token/expiration',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => '3600',
}

keystone_config { 'token/provider':
  name   => 'token/provider',
  notify => ['Service[keystone]', 'Exec[keystone-manage db_sync]', 'Exec[keystone-manage pki_setup]', 'Service[httpd]'],
  value  => 'keystone.token.providers.uuid.Provider',
}

keystone_endpoint { 'RegionOne/keystone':
  ensure       => 'present',
  admin_url    => 'http://172.16.1.2:35357/v2.0',
  internal_url => 'http://172.16.1.2:5000/v2.0',
  name         => 'RegionOne/keystone',
  public_url   => 'https://public.fuel.local:5000/v2.0',
}

keystone_role { 'admin':
  ensure => 'present',
  name   => 'admin',
}

keystone_service { 'keystone':
  ensure      => 'present',
  description => 'OpenStack Identity Service',
  name        => 'keystone',
  type        => 'identity',
}

keystone_tenant { 'admin':
  ensure      => 'present',
  description => 'admin tenant',
  enabled     => 'true',
  name        => 'admin',
}

keystone_tenant { 'services':
  ensure      => 'present',
  description => 'Tenant for the openstack services',
  enabled     => 'true',
  name        => 'services',
}

keystone_user { 'admin':
  ensure                => 'present',
  email                 => 'admin@localhost',
  enabled               => 'true',
  ignore_default_tenant => 'false',
  name                  => 'admin',
  password              => 'admin',
  tenant                => 'admin',
}

keystone_user_role { 'admin@admin':
  ensure => 'present',
  name   => 'admin@admin',
  roles  => 'admin',
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

package { 'httpd':
  ensure => 'installed',
  name   => 'apache2',
  notify => 'Class[Apache::Service]',
}

package { 'keystone':
  ensure => 'present',
  before => ['Package[httpd]', 'Exec[remove_keystone_override]', 'Exec[remove_keystone_override]'],
  name   => 'keystone',
  notify => ['Service[keystone]', 'Service[httpd]'],
  tag    => ['openstack', 'keystone-package'],
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

package { 'python-keystoneclient':
  ensure => 'present',
  name   => 'python-keystoneclient',
  tag    => 'openstack',
}

package { 'python-memcache':
  ensure => 'present',
  name   => 'python-memcache',
}

package { 'python-mysqldb':
  ensure => 'present',
  name   => 'python-mysqldb',
}

package { 'python-openstackclient':
  ensure => 'present',
  name   => 'python-openstackclient',
  tag    => 'openstack',
}

service { 'httpd':
  ensure     => 'running',
  before     => ['Keystone_endpoint[RegionOne/keystone]', 'Keystone_role[admin]', 'Keystone_service[keystone]', 'Keystone_tenant[services]', 'Keystone_tenant[admin]', 'Keystone_user[admin]', 'Keystone_user_role[admin@admin]', 'Haproxy_backend_status[keystone-public]', 'Haproxy_backend_status[keystone-admin]'],
  enable     => 'true',
  hasrestart => 'true',
  name       => 'apache2',
  restart    => 'sleep 30 && apachectl graceful || apachectl restart',
}

service { 'keystone':
  ensure     => 'stopped',
  before     => ['Haproxy_backend_status[keystone-public]', 'Haproxy_backend_status[keystone-admin]'],
  enable     => 'false',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'keystone',
  provider   => 'upstart',
  tag        => 'keystone-service',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'keystone':
  name         => 'keystone',
  package_name => 'keystone',
  service_name => 'keystone',
}

user { 'keystone':
  ensure  => 'present',
  gid     => 'keystone',
  name    => 'keystone',
  require => 'Package[keystone]',
  system  => 'true',
}

user { 'www-data':
  ensure  => 'present',
  gid     => 'www-data',
  name    => 'www-data',
  require => 'Package[httpd]',
}

