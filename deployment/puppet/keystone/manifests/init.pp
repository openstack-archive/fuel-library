#
# Module for managing keystone config.
#
# == Parameters
#
# [*package_ensure*]
#   (optional) Desired ensure state of packages.
#   accepts latest or specific versions.
#   Defaults to present.
#
# [*client_package_ensure*]
#   (optional) Desired ensure state of the client package.
#   accepts latest or specific versions.
#   Defaults to present.
#
# [*public_port*]
#   (optional) Port that keystone binds to.
#   Defaults to '5000'
#
# [*compute_port*]
#   (optional) DEPRECATED The port for compute servie.
#   Defaults to '8774'
#
# [*admin_port*]
#   (optional) Port that can be used for admin tasks.
#   Defaults to '35357'
#
# [*admin_token*]
#   Admin token that can be used to authenticate as a keystone
#   admin. Required.
#
# [*verbose*]
#   (optional) Rather keystone should log at verbose level.
#   Defaults to false.
#
# [*debug*]
#   (optional) Rather keystone should log at debug level.
#   Defaults to False.
#
# [*use_syslog*]
#   (optional) Use syslog for logging.
#   Defaults to false.
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines.
#   Defaults to 'LOG_USER'.
#
# [*catalog_type*]
#   (optional) Type of catalog that keystone uses to store endpoints,services.
#   Defaults to sql. (Also accepts template)
#
# [*catalog_driver*]
#   (optional) Catalog driver used by Keystone to store endpoints and services.
#   Setting this value will override and ignore catalog_type.
#   Defaults to false.
#
# [*catalog_template_file*]
#   (optional) Path to the catalog used if catalog_type equals 'template'.
#   Defaults to '/etc/keystone/default_catalog.templates'
#
# [*token_provider*]
#   (optional) Format keystone uses for tokens.
#   Defaults to 'keystone.token.providers.uuid.Provider'
#   Supports PKI, PKIZ, Fernet, and UUID.
#
# [*token_driver*]
#   (optional) Driver to use for managing tokens.
#   Defaults to 'keystone.token.persistence.backends.sql.Token'
#
# [*token_expiration*]
#   (optional) Amount of time a token should remain valid (seconds).
#   Defaults to 3600 (1 hour).
#
# [*revoke_driver*]
#   (optional) Driver for token revocation.
#   Defaults to 'keystone.contrib.revoke.backends.sql.Revoke'
#
# [*cache_dir*]
#   (optional) Directory created when token_provider is pki.
#   Defaults to /var/cache/keystone.
#
# [*memcache_servers*]
#   (optional) List of memcache servers in format of server:port.
#   Used with token_driver 'keystone.token.backends.memcache.Token'.
#   Defaults to false. Example: ['localhost:11211']
#
# [*cache_backend*]
#   (optional) Dogpile.cache backend module. It is recommended that Memcache with pooling
#   (keystone.cache.memcache_pool) or Redis (dogpile.cache.redis) be used in production.
#   This has no effects unless 'memcache_servers' is set.
#   Defaults to 'keystone.common.cache.noop'
#
# [*cache_backend_argument*]
#   (optional) List of arguments in format of argname:value supplied to the backend module.
#   Specify this option once per argument to be passed to the dogpile.cache backend.
#   This has no effects unless 'memcache_servers' is set.
#   Default to undef.
#
# [*debug_cache_backend*]
#   (optional) Extra debugging from the cache backend (cache keys, get/set/delete calls).
#   This has no effects unless 'memcache_servers' is set.
#   Default to false.
#
# [*token_caching*]
#   (optional) Toggle for token system caching. This has no effects unless 'memcache_servers' is set.
#   Default to true.
#
# [*manage_service*]
#   (Optional) If Puppet should manage service startup / shutdown.
#   Defaults to true.
#
# [*enabled*]
#  (optional) If the keystone services should be enabled.
#   Default to true.
#
# [*database_connection*]
#   (optional) Url used to connect to database.
#   Defaults to sqlite:////var/lib/keystone/keystone.db
#
# [*database_idle_timeout*]
#   (optional) Timeout when db connections should be reaped.
#   Defaults to 200.
#
# [*enable_pki_setup*]
#   (optional) Enable call to pki_setup to generate the cert for signing pki tokens and
#   revocation lists if it doesn't already exist. This generates a cert and key stored in file
#   locations based on the signing_certfile and signing_keyfile paramters below. If you are
#   providing your own signing cert, make this false.
#   Default to true.
#
# [*signing_certfile*]
#   (optional) Location of the cert file for signing pki tokens and revocation lists.
#   Note that if this file already exists (i.e. you are providing your own signing cert),
#   the file will not be overwritten, even if enable_pki_setup is set to true.
#   Default: /etc/keystone/ssl/certs/signing_cert.pem
#
# [*signing_keyfile*]
#   (optional) Location of the key file for signing pki tokens and revocation lists.
#   Note that if this file already exists (i.e. you are providing your own signing cert), the file
#   will not be overwritten, even if enable_pki_setup is set to true.
#   Default: /etc/keystone/ssl/private/signing_key.pem
#
# [*signing_ca_certs*]
#   (optional) Use this CA certs file along with signing_certfile/signing_keyfile for
#   signing pki tokens and revocation lists.
#   Default: /etc/keystone/ssl/certs/ca.pem
#
# [*signing_ca_key*]
#   (optional) Use this CA key file along with signing_certfile/signing_keyfile for signing
#   pki tokens and revocation lists.
#   Default: /etc/keystone/ssl/private/cakey.pem
#
# [*signing_cert_subject*]
#   (optional) Certificate subject (auto generated certificate) for token signing.
#   Defaults to '/C=US/ST=Unset/L=Unset/O=Unset/CN=www.example.com'
#
# [*signing_key_size*]
#   (optional) Key size (in bits) for token signing cert (auto generated certificate)
#   Defaults to 2048
#
# [*rabbit_host*]
#   (optional) Location of rabbitmq installation.
#    Defaults to localhost.
#
# [*rabbit_port*]
#   (optional) Port for rabbitmq instance.
#   Defaults to 5672.
#
# [*rabbit_hosts*]
#   (optional) Location of rabbitmq installation.
#   Defaults to undef.
#
# [*rabbit_password*]
#   (optional) Password used to connect to rabbitmq.
#   Defaults to guest.
#
# [*rabbit_userid*]
#   (optional) User used to connect to rabbitmq.
#   Defaults to guest.
#
# [*rabbit_virtual_host*]
#   (optional) The RabbitMQ virtual host.
#   Defaults to /.
#
# [*rabbit_use_ssl*]
#   (optional) Connect over SSL for RabbitMQ
#   Defaults to false
#
# [*kombu_ssl_ca_certs*]
#   (optional) SSL certification authority file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_certfile*]
#   (optional) SSL cert file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_keyfile*]
#   (optional) SSL key file (valid only if SSL enabled).
#   Defaults to undef
#
# [*kombu_ssl_version*]
#   (optional) SSL version to use (valid only if SSL enabled).
#   Valid values are TLSv1, SSLv23 and SSLv3. SSLv2 may be
#   available on some distributions.
#   Defaults to 'TLSv1'
#
# [*notification_driver*]
#   RPC driver. Not enabled by default
#
# [*notification_topics*]
#   (optional) AMQP topics to publish to when using the RPC notification driver.
#   Default to false.
#
# [*notification_format*]
#   Format for the notifications. Valid values are 'basic' and 'cadf'.
#   Default to undef
#
# [*control_exchange*]
#   (optional) AMQP exchange to connect to if using RabbitMQ or Qpid
#   Default to false.
#
# [*public_bind_host*]
#   (optional) The IP address of the public network interface to listen on
#   Default to '0.0.0.0'.
#
# [*admin_bind_host*]
#   (optional) The IP address of the public network interface to listen on
#   Default to '0.0.0.0'.
#
# [*log_dir*]
#   (optional) Directory where logs should be stored
#   If set to boolean false, it will not log to any directory
#   Defaults to '/var/log/keystone'
#
# [*log_file*]
#   (optional) Where to log
#   Defaults to false
#
# [*public_endpoint*]
#   (optional) The base public endpoint URL for keystone that are
#   advertised to clients (NOTE: this does NOT affect how
#   keystone listens for connections) (string value)
#   If set to false, no public_endpoint will be defined in keystone.conf.
#   Sample value: 'http://localhost:5000/'
#   Defaults to false
#
# [*admin_endpoint*]
#   (optional) The base admin endpoint URL for keystone that are
#   advertised to clients (NOTE: this does NOT affect how keystone listens
#   for connections) (string value)
#   If set to false, no admin_endpoint will be defined in keystone.conf.
#   Sample value: 'http://localhost:35357/'
#   Defaults to false
#
# [*enable_ssl*]
#   (optional) Toggle for SSL support on the keystone eventlet servers.
#   (boolean value)
#   Defaults to false
#
# [*ssl_certfile*]
#   (optional) Path of the certfile for SSL. (string value)
#   Defaults to '/etc/keystone/ssl/certs/keystone.pem'
#
# [*ssl_keyfile*]
#   (optional) Path of the keyfile for SSL. (string value)
#   Defaults to '/etc/keystone/ssl/private/keystonekey.pem'
#
# [*ssl_ca_certs*]
#   (optional) Path of the ca cert file for SSL. (string value)
#   Defaults to '/etc/keystone/ssl/certs/ca.pem'
#
# [*ssl_ca_key*]
#   (optional) Path of the CA key file for SSL (string value)
#   Defaults to '/etc/keystone/ssl/private/cakey.pem'
#
# [*ssl_cert_subject*]
#   (optional) SSL Certificate Subject (auto generated certificate)
#   (string value)
#   Defaults to '/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost'
#
# [*mysql_module*]
#   (optional) Deprecated. Does nothing.
#
# [*validate_service*]
#   (optional) Whether to validate keystone connections after
#   the service is started.
#   Defaults to false
#
# [*validate_insecure*]
#   (optional) Whether to validate keystone connections
#   using the --insecure option with keystone client.
#   Defaults to false
#
# [*validate_cacert*]
#   (optional) Whether to validate keystone connections
#   using the specified argument with the --os-cacert option
#   with keystone client.
#   Defaults to undef
#
# [*validate_auth_url*]
#   (optional) The url to validate keystone against
#   Defaults to undef
#
# [*service_provider*]
#   (optional) Provider, that can be used for keystone service.
#   Default value defined in keystone::params for given operation system.
#   If you use Pacemaker or another Cluster Resource Manager, you can make
#   custom service provider for changing start/stop/status behavior of service,
#   and set it here.
#
# [*service_name*]
#   (optional) Name of the service that will be providing the
#   server functionality of keystone.  For example, the default
#   is just 'keystone', which means keystone will be run as a
#   standalone eventlet service, and will able to be managed
#   separately by the operating system's service manager.  For
#   example, you will be able to use
#   service openstack-keystone restart
#   to restart the service.
#   If the value is 'httpd', this means keystone will be a web
#   service, and you must use another class to configure that
#   web service.  For example, after calling class {'keystone'...}
#   use class { 'keystone::wsgi::apache'...} to make keystone be
#   a web app using apache mod_wsgi.
#   Defaults to '$::keystone::params::service_name'
#   NOTE: validate_service only applies if the default value is used.
#
# [*paste_config*]
#   (optional) Name of the paste configuration file that defines the
#   available pipelines. (string value)
#   Defaults to '/usr/share/keystone/keystone-dist-paste.ini' on RedHat and
#   undef on other platforms.
#
# [*max_token_size*]
#   (optional) maximum allowable Keystone token size
#   Defaults to undef
#
# [*admin_workers*]
#   (optional) The number of worker processes to serve the admin WSGI application.
#   Defaults to max($::processorcount, 2)
#
# [*public_workers*]
#   (optional) The number of worker processes to serve the public WSGI application.
#   Defaults to max($::processorcount, 2)
#
# [*sync_db*]
#   (Optional) Run db sync on the node.
#   Defaults to true
#
# [*enable_fernet_setup*]
#   (Optional) Setup keystone for fernet tokens. This is typically only
#   run on a single node, then the keys are replicated to the other nodes
#   in a cluster. You would typically also pair this with a fernet token
#   provider setting.
#   Defaults to false
#
# [*fernet_key_repository*]
#   (Optional) Location for the fernet key repository. This value must
#   be set if enable_fernet_setup is set to true.
#   Defaults to '/etc/keystone/fernet-keys'
#
# [*fernet_max_active_keys*]
#   (Optional) Number of maximum active Fernet keys. Integer > 0.
#   Defaults to undef
#
# == Dependencies
#  None
#
# == Examples
#
#   class { 'keystone':
#     log_verbose => 'True',
#     admin_token => 'my_special_token',
#   }
#
#   OR
#
#   class { 'keystone':
#      ...
#      service_name => 'httpd',
#      ...
#   }
#   class { 'keystone::wsgi::apache':
#      ...
#   }
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone(
  $admin_token,
  $package_ensure         = 'present',
  $client_package_ensure  = 'present',
  $public_bind_host       = '0.0.0.0',
  $admin_bind_host        = '0.0.0.0',
  $public_port            = '5000',
  $admin_port             = '35357',
  $verbose                = false,
  $debug                  = false,
  $log_dir                = '/var/log/keystone',
  $log_file               = false,
  $use_syslog             = false,
  $log_facility           = 'LOG_USER',
  $catalog_type           = 'sql',
  $catalog_driver         = false,
  $catalog_template_file  = '/etc/keystone/default_catalog.templates',
  $token_provider         = 'keystone.token.providers.uuid.Provider',
  $token_driver           = 'keystone.token.persistence.backends.sql.Token',
  $token_expiration       = 3600,
  $revoke_driver          = 'keystone.contrib.revoke.backends.sql.Revoke',
  $public_endpoint        = false,
  $admin_endpoint         = false,
  $enable_ssl             = false,
  $ssl_certfile           = '/etc/keystone/ssl/certs/keystone.pem',
  $ssl_keyfile            = '/etc/keystone/ssl/private/keystonekey.pem',
  $ssl_ca_certs           = '/etc/keystone/ssl/certs/ca.pem',
  $ssl_ca_key             = '/etc/keystone/ssl/private/cakey.pem',
  $ssl_cert_subject       = '/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost',
  $cache_dir              = '/var/cache/keystone',
  $memcache_servers       = false,
  $manage_service         = true,
  $cache_backend          = 'keystone.common.cache.noop',
  $cache_backend_argument = undef,
  $debug_cache_backend    = false,
  $token_caching          = true,
  $enabled                = true,
  $database_connection    = 'sqlite:////var/lib/keystone/keystone.db',
  $database_idle_timeout  = '200',
  $enable_pki_setup       = true,
  $signing_certfile       = '/etc/keystone/ssl/certs/signing_cert.pem',
  $signing_keyfile        = '/etc/keystone/ssl/private/signing_key.pem',
  $signing_ca_certs       = '/etc/keystone/ssl/certs/ca.pem',
  $signing_ca_key         = '/etc/keystone/ssl/private/cakey.pem',
  $signing_cert_subject   = '/C=US/ST=Unset/L=Unset/O=Unset/CN=www.example.com',
  $signing_key_size       = 2048,
  $rabbit_host            = 'localhost',
  $rabbit_hosts           = false,
  $rabbit_password        = 'guest',
  $rabbit_port            = '5672',
  $rabbit_userid          = 'guest',
  $rabbit_virtual_host    = '/',
  $rabbit_use_ssl         = false,
  $kombu_ssl_ca_certs     = undef,
  $kombu_ssl_certfile     = undef,
  $kombu_ssl_keyfile      = undef,
  $kombu_ssl_version      = 'TLSv1',
  $notification_driver    = false,
  $notification_topics    = false,
  $notification_format    = undef,
  $control_exchange       = false,
  $validate_service       = false,
  $validate_insecure      = false,
  $validate_auth_url      = false,
  $validate_cacert        = undef,
  $paste_config           = $::keystone::params::paste_config,
  $service_provider       = $::keystone::params::service_provider,
  $service_name           = $::keystone::params::service_name,
  $max_token_size         = undef,
  $admin_workers          = max($::processorcount, 2),
  $public_workers         = max($::processorcount, 2),
  $sync_db                = true,
  $enable_fernet_setup    = false,
  $fernet_key_repository  = '/etc/keystone/fernet-keys',
  $fernet_max_active_keys = undef,
  # DEPRECATED PARAMETERS
  $mysql_module           = undef,
  $compute_port           = undef,
) inherits keystone::params {

  if ! $catalog_driver {
    validate_re($catalog_type, 'template|sql')
  }

  if $mysql_module {
    warning('The mysql_module parameter is deprecated. The latest 2.x mysql module will be used.')
  }

  if ($admin_endpoint and 'v2.0' in $admin_endpoint) {
    warning('Version string /v2.0/ should not be included in keystone::admin_endpoint')
  }

  if ($public_endpoint and 'v2.0' in $public_endpoint) {
    warning('Version string /v2.0/ should not be included in keystone::public_endpoint')
  }

  if $rabbit_use_ssl {
    if !$kombu_ssl_ca_certs {
      fail('The kombu_ssl_ca_certs parameter is required when rabbit_use_ssl is set to true')
    }
    if !$kombu_ssl_certfile {
      fail('The kombu_ssl_certfile parameter is required when rabbit_use_ssl is set to true')
    }
    if !$kombu_ssl_keyfile {
      fail('The kombu_ssl_keyfile parameter is required when rabbit_use_ssl is set to true')
    }
  }

  File['/etc/keystone/keystone.conf'] -> Keystone_config<||> ~> Service[$service_name]
  Keystone_config<||> ~> Exec<| title == 'keystone-manage db_sync'|>
  Keystone_config<||> ~> Exec<| title == 'keystone-manage pki_setup'|>
  Keystone_config<||> ~> Exec<| title == 'keystone-manage fernet_setup'|>

  include ::keystone::params

  package { 'keystone':
    ensure => $package_ensure,
    name   => $::keystone::params::package_name,
    tag    => 'openstack',
  }
  if $client_package_ensure == 'present' {
    include '::openstacklib::openstackclient'
  } else {
    class { '::openstacklib::openstackclient':
      package_ensure => $client_package_ensure,
    }
  }

  group { 'keystone':
    ensure  => present,
    system  => true,
    require => Package['keystone'],
  }

  user { 'keystone':
    ensure  => 'present',
    gid     => 'keystone',
    system  => true,
    require => Package['keystone'],
  }

  file { ['/etc/keystone', '/var/log/keystone', '/var/lib/keystone']:
    ensure  => directory,
    mode    => '0750',
    owner   => 'keystone',
    group   => 'keystone',
    require => Package['keystone'],
    notify  => Service[$service_name],
  }

  file { '/etc/keystone/keystone.conf':
    ensure  => present,
    mode    => '0600',
    owner   => 'keystone',
    group   => 'keystone',
    require => Package['keystone'],
    notify  => Service[$service_name],
  }

  keystone_config {
    'DEFAULT/admin_token':      value => $admin_token, secret => true;
    'DEFAULT/public_bind_host': value => $public_bind_host;
    'DEFAULT/admin_bind_host':  value => $admin_bind_host;
    'DEFAULT/public_port':      value => $public_port;
    'DEFAULT/admin_port':       value => $admin_port;
    'DEFAULT/verbose':          value => $verbose;
    'DEFAULT/debug':            value => $debug;
  }

  if $compute_port {
    warning('The compute_port parameter is deprecated and will be removed in L')
    keystone_config {
      'DEFAULT/compute_port': value => $compute_port;
    }
  } else {
    keystone_config {
      'DEFAULT/compute_port': ensure => absent;
    }
  }

  # Endpoint configuration
  if $public_endpoint {
    keystone_config {
      'DEFAULT/public_endpoint': value => $public_endpoint;
    }
  } else {
    keystone_config {
      'DEFAULT/public_endpoint': ensure => absent;
    }
  }
  if $admin_endpoint {
    keystone_config {
      'DEFAULT/admin_endpoint': value => $admin_endpoint;
    }
  } else {
    keystone_config {
      'DEFAULT/admin_endpoint': ensure => absent;
    }
  }
  # requirements for memcache token driver
  if ($token_driver =~ /memcache/ ) {
    package { 'python-memcache':
      ensure => present,
      name   => $::keystone::params::python_memcache_package_name,
    }
  }

  # token driver config
  keystone_config {
    'token/driver':     value => $token_driver;
    'token/expiration': value => $token_expiration;
  }

  if $revoke_driver {
    keystone_config {
      'revoke/driver':    value => $revoke_driver;
    }
  } else {
    keystone_config {
      'revoke/driver':    ensure => absent;
    }
  }

  # ssl config
  if ($enable_ssl) {
    keystone_config {
      'ssl/enable':              value  => true;
      'ssl/certfile':            value  => $ssl_certfile;
      'ssl/keyfile':             value  => $ssl_keyfile;
      'ssl/ca_certs':            value  => $ssl_ca_certs;
      'ssl/ca_key':              value  => $ssl_ca_key;
      'ssl/cert_subject':        value  => $ssl_cert_subject;
    }
  } else {
    keystone_config {
      'ssl/enable':              value  => false;
    }
  }

  if($database_connection =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
    require 'mysql::bindings'
    require 'mysql::bindings::python'
  } elsif($database_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

  } elsif($database_connection =~ /sqlite:\/\//) {

  } else {
    fail("Invalid db connection ${database_connection}")
  }

  # memcache connection config
  if $memcache_servers {
    validate_array($memcache_servers)
    Service<| title == 'memcached' |> -> Service['keystone']
    keystone_config {
      'cache/enabled':              value => true;
      'cache/backend':              value => $cache_backend;
      'cache/debug_cache_backend':  value => $debug_cache_backend;
      'token/caching':              value => $token_caching;
      'memcache/servers':           value => join($memcache_servers, ',');
    }
    if $cache_backend_argument {
      validate_array($cache_backend_argument)
      keystone_config {
        'cache/backend_argument':   value => join($cache_backend_argument, ',');
      }
    } else {
      keystone_config {
        'cache/backend_argument':  ensure => absent;
      }
    }
  } else {
    keystone_config {
      'cache/enabled':             ensure => absent;
      'cache/backend':             ensure => absent;
      'cache/backend_argument':    ensure => absent;
      'cache/debug_cache_backend': ensure => absent;
      'token/caching':             ensure => absent;
      'memcache/servers':          ensure => absent;
    }
  }

  # db connection config
  keystone_config {
    'database/connection':   value => $database_connection, secret => true;
    'database/idle_timeout': value => $database_idle_timeout;
  }

  # configure based on the catalog backend
  if $catalog_driver {
    $catalog_driver_real = $catalog_driver
  }
  elsif ($catalog_type == 'template') {
    $catalog_driver_real = 'keystone.catalog.backends.templated.Catalog'
  }
  elsif ($catalog_type == 'sql') {
    $catalog_driver_real = 'keystone.catalog.backends.sql.Catalog'
  }

  keystone_config {
    'catalog/driver':        value => $catalog_driver_real;
    'catalog/template_file': value => $catalog_template_file;
  }

  # Set the signing key/cert configuration values.
  keystone_config {
    'signing/certfile':     value => $signing_certfile;
    'signing/keyfile':      value => $signing_keyfile;
    'signing/ca_certs':     value => $signing_ca_certs;
    'signing/ca_key':       value => $signing_ca_key;
    'signing/cert_subject': value => $signing_cert_subject;
    'signing/key_size':     value => $signing_key_size;
  }

  # Create cache directory used for signing.
  file { $cache_dir:
    ensure => directory,
  }

  # Only do pki_setup if we were asked to do so.  This is needed
  # regardless of the token provider since token revocation lists
  # are always signed.
  if $enable_pki_setup {
    exec { 'keystone-manage pki_setup':
      path        => '/usr/bin',
      user        => 'keystone',
      refreshonly => true,
      creates     => $signing_keyfile,
      notify      => Service[$service_name],
      subscribe   => Package['keystone'],
      require     => User['keystone'],
    }
  }

  keystone_config { 'token/provider': value => $token_provider }

  if $max_token_size {
    keystone_config { 'DEFAULT/max_token_size': value => $max_token_size }
  } else {
    keystone_config { 'DEFAULT/max_token_size': ensure => absent }
  }

  if $notification_driver {
    keystone_config { 'DEFAULT/notification_driver': value => $notification_driver }
  } else {
    keystone_config { 'DEFAULT/notification_driver': ensure => absent }
  }
  if $notification_topics {
    keystone_config { 'DEFAULT/notification_topics': value => $notification_topics }
  } else {
    keystone_config { 'DEFAULT/notification_topics': ensure => absent }
  }
  if $notification_format {
    keystone_config { 'DEFAULT/notification_format': value => $notification_format }
  } else {
    keystone_config { 'DEFAULT/notification_format': ensure => absent }
  }
  if $control_exchange {
    keystone_config { 'DEFAULT/control_exchange': value => $control_exchange }
  } else {
    keystone_config { 'DEFAULT/control_exchange': ensure => absent }
  }

  keystone_config {
    'DEFAULT/rabbit_password':     value => $rabbit_password, secret => true;
    'DEFAULT/rabbit_userid':       value => $rabbit_userid;
    'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
  }

  if $rabbit_hosts {
    keystone_config { 'DEFAULT/rabbit_hosts':     value => join($rabbit_hosts, ',') }
    keystone_config { 'DEFAULT/rabbit_ha_queues': value => true }
  } else {
    keystone_config { 'DEFAULT/rabbit_host':      value => $rabbit_host }
    keystone_config { 'DEFAULT/rabbit_port':      value => $rabbit_port }
    keystone_config { 'DEFAULT/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}" }
    keystone_config { 'DEFAULT/rabbit_ha_queues': value => false }
  }

  keystone_config { 'DEFAULT/rabbit_use_ssl': value => $rabbit_use_ssl }
  if $rabbit_use_ssl {
    keystone_config {
      'DEFAULT/kombu_ssl_ca_certs': value => $kombu_ssl_ca_certs;
      'DEFAULT/kombu_ssl_certfile': value => $kombu_ssl_certfile;
      'DEFAULT/kombu_ssl_keyfile':  value => $kombu_ssl_keyfile;
      'DEFAULT/kombu_ssl_version':  value => $kombu_ssl_version;
    }
  } else {
    keystone_config {
      'DEFAULT/kombu_ssl_ca_certs': ensure => absent;
      'DEFAULT/kombu_ssl_certfile': ensure => absent;
      'DEFAULT/kombu_ssl_keyfile':  ensure => absent;
      'DEFAULT/kombu_ssl_version':  ensure => absent;
    }
  }

  keystone_config {
    'DEFAULT/admin_workers':  value => $admin_workers;
    'DEFAULT/public_workers': value => $public_workers;
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  } else {
    warning('Execution of db_sync does not depend on $enabled anymore. Please use sync_db instead.')
  }

  if $service_name == $::keystone::params::service_name {
    if $validate_service {
      if $validate_auth_url {
        $v_auth_url = $validate_auth_url
      } else {
        $v_auth_url = $admin_endpoint
      }

      class { '::keystone::service':
        ensure         => $service_ensure,
        service_name   => $service_name,
        enable         => $enabled,
        hasstatus      => true,
        hasrestart     => true,
        provider       => $service_provider,
        validate       => true,
        admin_endpoint => $v_auth_url,
        admin_token    => $admin_token,
        insecure       => $validate_insecure,
        cacert         => $validate_cacert,
      }
    } else {
      class { '::keystone::service':
        ensure       => $service_ensure,
        service_name => $service_name,
        enable       => $enabled,
        hasstatus    => true,
        hasrestart   => true,
        provider     => $service_provider,
        validate     => false,
      }
    }
  } elsif $service_name == 'httpd' {
    class { '::keystone::service':
      ensure       => 'stopped',
      service_name => $::keystone::params::service_name,
      enable       => false,
      provider     => $service_provider,
      validate     => false,
    }
  } else {
    fail('Invalid service_name. Either keystone/openstack-keystone for running as a standalone service, or httpd for being run by a httpd server')
  }

  if $sync_db {
    include ::keystone::db::sync
    Class['::keystone::db::sync'] ~> Service[$service_name]
  }

  # Syslog configuration
  if $use_syslog {
    keystone_config {
      'DEFAULT/use_syslog':           value  => true;
      'DEFAULT/syslog_log_facility':  value  => $log_facility;
    }
  } else {
    keystone_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

  if $log_file {
    keystone_config {
      'DEFAULT/log_file': value => $log_file;
      'DEFAULT/log_dir':  value => $log_dir;
    }
  } else {
    if $log_dir {
      keystone_config {
        'DEFAULT/log_dir':  value  => $log_dir;
        'DEFAULT/log_file': ensure => absent;
      }
    } else {
      keystone_config {
        'DEFAULT/log_dir':  ensure => absent;
        'DEFAULT/log_file': ensure => absent;
      }
    }
  }

  if $paste_config {
    keystone_config {
        'paste_deploy/config_file':   value => $paste_config;
    }
  } else {
    keystone_config {
        'paste_deploy/config_file':   ensure => absent;
    }
  }

  # Fernet tokens support
  if $enable_fernet_setup {
    validate_string($fernet_key_repository)

    exec { 'keystone-manage fernet_setup':
      path        => '/usr/bin',
      user        => 'keystone',
      refreshonly => true,
      creates     => "${fernet_key_repository}/0",
      notify      => Service[$service_name],
      subscribe   => [Package['keystone'], Keystone_config['fernet_tokens/key_repository']],
    }
  }

  if $fernet_key_repository {
    keystone_config {
        'fernet_tokens/key_repository':   value => $fernet_key_repository;
    }
  } else {
    keystone_config {
        'fernet_tokens/key_repository':   ensure => absent;
    }
  }

  if $fernet_max_active_keys {
    keystone_config {
        'fernet_tokens/max_active_keys':   value => $fernet_max_active_keys;
    }
  } else {
    keystone_config {
        'fernet_tokens/max_active_keys':   ensure => absent;
    }
  }

}
