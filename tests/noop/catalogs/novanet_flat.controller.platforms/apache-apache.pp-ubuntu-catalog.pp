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

apache::mpm { 'worker':
  apache_version => '2.4',
  lib_path       => '/usr/lib/apache2/modules',
  name           => 'worker',
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

class { 'Apache::Mod::Worker':
  apache_version      => '2.4',
  maxclients          => '3213',
  maxrequestsperchild => '0',
  maxsparethreads     => '1606',
  minsparethreads     => '25',
  name                => 'Apache::Mod::Worker',
  serverlimit         => '128',
  startservers        => '4',
  threadlimit         => '64',
  threadsperchild     => '25',
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
  purge_configs          => 'true',
  purge_vdir             => 'false',
  sendfile               => 'On',
  server_root            => '/etc/apache2',
  server_signature       => 'Off',
  server_tokens          => 'Prod',
  serveradmin            => 'root@localhost',
  servername             => 'node-1',
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

class { 'Osnailyfacter::Apache':
  listen_ports     => ['80', '8888', '5000', '35357'],
  logrotate_rotate => '52',
  name             => 'Osnailyfacter::Apache',
  purge_configs    => 'true',
}

class { 'Osnailyfacter::Apache_mpm':
  name => 'Osnailyfacter::Apache_mpm',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Sysctl::Base':
  name => 'Sysctl::Base',
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

exec { 'concat_/etc/apache2/ports.conf':
  alias     => 'concat_/tmp//_etc_apache2_ports.conf',
  command   => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_apache2_ports.conf/fragments.concat.out" -d "/tmp//_etc_apache2_ports.conf"',
  notify    => 'File[/etc/apache2/ports.conf]',
  require   => ['File[/tmp//_etc_apache2_ports.conf]', 'File[/tmp//_etc_apache2_ports.conf/fragments]', 'File[/tmp//_etc_apache2_ports.conf/fragments.concat]'],
  subscribe => 'File[/tmp//_etc_apache2_ports.conf]',
  unless    => '/tmp//bin/concatfragments.rb -o "/tmp//_etc_apache2_ports.conf/fragments.concat.out" -d "/tmp//_etc_apache2_ports.conf" -t',
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

file { '/etc/apache2/apache2.conf':
  ensure  => 'file',
  content => '# Security
ServerTokens Prod
ServerSignature Off
TraceEnable Off

ServerName "node-1"
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
  purge   => 'true',
  recurse => 'true',
  require => 'Package[httpd]',
}

file { '/etc/apache2/mods-available/worker.conf':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => '<IfModule mpm_worker_module>
  ServerLimit         128
  StartServers        4
  MaxClients          3213
  MinSpareThreads     25
  MaxSpareThreads     1606
  ThreadsPerChild     25
  MaxRequestsPerChild 0
  ThreadLimit         64
</IfModule>
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/worker.conf',
  require => 'Exec[mkdir /etc/apache2/mods-available]',
}

file { '/etc/apache2/mods-available/worker.load':
  ensure  => 'file',
  before  => 'File[/etc/apache2/mods-available]',
  content => 'LoadModule mpm_worker_module /usr/lib/apache2/modules/mod_mpm_worker.so
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-available/worker.load',
  require => ['Package[httpd]', 'Exec[mkdir /etc/apache2/mods-available]'],
}

file { '/etc/apache2/mods-available':
  ensure  => 'directory',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-available',
  purge   => 'false',
  recurse => 'true',
  require => 'Package[httpd]',
}

file { '/etc/apache2/mods-enabled/worker.conf':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/worker.conf',
  require => 'Exec[mkdir /etc/apache2/mods-enabled]',
  target  => '/etc/apache2/mods-available/worker.conf',
}

file { '/etc/apache2/mods-enabled/worker.load':
  ensure  => 'link',
  before  => 'File[/etc/apache2/mods-enabled]',
  group   => 'root',
  mode    => '0644',
  notify  => 'Class[Apache::Service]',
  owner   => 'root',
  path    => '/etc/apache2/mods-enabled/worker.load',
  require => 'Exec[mkdir /etc/apache2/mods-enabled]',
  target  => '/etc/apache2/mods-available/worker.load',
}

file { '/etc/apache2/mods-enabled':
  ensure  => 'directory',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/mods-enabled',
  purge   => 'true',
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
  purge   => 'true',
  recurse => 'true',
  require => 'Package[httpd]',
}

file { '/etc/apache2/sites-enabled':
  ensure  => 'directory',
  notify  => 'Class[Apache::Service]',
  path    => '/etc/apache2/sites-enabled',
  purge   => 'true',
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

sleep 180
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

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
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

file { '/var/log/apache2':
  ensure  => 'directory',
  before  => 'Concat[15-default.conf]',
  path    => '/var/log/apache2',
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

group { 'www-data':
  ensure  => 'present',
  name    => 'www-data',
  require => 'Package[httpd]',
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

package { 'mime-support':
  ensure => 'installed',
  before => 'File[mime.conf]',
  name   => 'mime-support',
}

service { 'httpd':
  ensure => 'running',
  enable => 'true',
  name   => 'apache2',
}

stage { 'main':
  name => 'main',
}

sysctl::value { 'net.core.somaxconn':
  key     => 'net.core.somaxconn',
  name    => 'net.core.somaxconn',
  require => 'Class[Sysctl::Base]',
  value   => '4096',
}

sysctl::value { 'net.ipv4.tcp_max_syn_backlog':
  key     => 'net.ipv4.tcp_max_syn_backlog',
  name    => 'net.ipv4.tcp_max_syn_backlog',
  require => 'Class[Sysctl::Base]',
  value   => '8192',
}

sysctl { 'net.core.somaxconn':
  before => 'Sysctl_runtime[net.core.somaxconn]',
  name   => 'net.core.somaxconn',
  val    => '4096',
}

sysctl { 'net.ipv4.tcp_max_syn_backlog':
  before => 'Sysctl_runtime[net.ipv4.tcp_max_syn_backlog]',
  name   => 'net.ipv4.tcp_max_syn_backlog',
  val    => '8192',
}

sysctl_runtime { 'net.core.somaxconn':
  name => 'net.core.somaxconn',
  val  => '4096',
}

sysctl_runtime { 'net.ipv4.tcp_max_syn_backlog':
  name => 'net.ipv4.tcp_max_syn_backlog',
  val  => '8192',
}

user { 'www-data':
  ensure  => 'present',
  gid     => 'www-data',
  name    => 'www-data',
  require => 'Package[httpd]',
}

