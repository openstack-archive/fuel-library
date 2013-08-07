# Class: puppetdb::server
#
# This class provides a simple way to get a puppetdb instance up and running
# with minimal effort.  It will install and configure all necessary packages for
# the puppetdb server, but will *not* manage the database (e.g., postgres) server
# or instance (unless you are using the embedded database, in which case there
# is not much to manage).
#
# This class is intended as a high-level abstraction to help simplify the process
# of getting your puppetdb server up and running; it manages the puppetdb
# package and service, as well as several puppetdb configuration files.  For
# maximum configurability, you may choose not to use this class.  You may prefer to
# manage the puppetdb package / service on your own, and perhaps use the
# individual classes inside of the `puppetdb::server` namespace to manage some
# or all of your configuration files.
#
# In addition to this class, you'll need to configure your puppetdb postgres
# database if you are using postgres.  You can optionally do by using the
# `puppetdb::database::postgresql` class.
#
# You'll also need to configure your puppet master to use puppetdb.  You can
# use the `puppetdb::master::config` class to accomplish this.
#
# Parameters:
#   ['ssl_listen_address'] - The address that the web server should bind to
#                            for HTTPS requests.  (defaults to `$::clientcert`.)
#   ['ssl_listen_port']    - The port on which the puppetdb web server should
#                            accept HTTPS requests.
#   ['database']           - Which database backend to use; legal values are
#                            `postgres` (default) or `embedded`.  (The `embedded`
#                            db can be used for very small installations or for
#                            testing, but is not recommended for use in production
#                            environments.  For more info, see the puppetdb docs.)
#   ['database_host']      - The hostname or IP address of the database server.
#                            (defaults to `localhost`; ignored for `embedded` db)
#   ['database_port']      - The port that the database server listens on.
#                            (defaults to `5432`; ignored for `embedded` db)
#   ['database_user']      - The name of the database user to connect as.
#                            (defaults to `puppetdb`; ignored for `embedded` db)
#   ['database_password']  - The password for the database user.
#                            (defaults to `puppetdb`; ignored for `embedded` db)
#   ['database_name']      - The name of the database instance to connect to.
#                            (defaults to `puppetdb`; ignored for `embedded` db)
#   ['puppetdb_version']   - The version of the `puppetdb` package that should
#                            be installed.  You may specify an explicit version
#                            number, 'present', or 'latest'.  Defaults to
#                            'present'.
#   ['manage_redhat_firewall'] - boolean indicating whether or not the module
#                            should open a port in the firewall on redhat-based
#                            systems.  Defaults to `true`.  This parameter is
#                            likely to change in future versions.  Possible
#                            changes include support for non-RedHat systems and
#                            finer-grained control over the firewall rule
#                            (currently, it simply opens up the postgres port to
#                            all TCP connections).
#   ['confdir']            - The puppetdb configuration directory; defaults to
#                            `/etc/puppetdb/conf.d`.
#
# Actions:
# - Creates and manages a puppetdb server
#
# Requires:
# - `inkling/postgresql`
#
# Sample Usage:
#     class { 'puppetdb::server':
#         database_host     => 'puppetdb-postgres',
#     }
#
class puppetdb::server(
  $ssl_listen_address      = $puppetdb::params::ssl_listen_address,
  $ssl_listen_port         = $puppetdb::params::ssl_listen_port,
  $listen_port             = $puppetdb::params::listen_port,
  $database                = $puppetdb::params::database,
  $database_host           = $puppetdb::params::database_host,
  $database_port           = $puppetdb::params::database_port,
  $database_username       = $puppetdb::params::database_username,
  $database_password       = $puppetdb::params::database_password,
  $database_name           = $puppetdb::params::database_name,
  $puppetdb_version        = $puppetdb::params::puppetdb_version,
  $confdir                 = $puppetdb::params::confdir,
  $gc_interval             = $puppetdb::params::gc_interval,
) inherits puppetdb::params {

  package { 'puppetdb':
    ensure => $puppetdb_version,
    notify => Service['puppetdb'],
  }

  class { 'puppetdb::server::firewall':}

  class { 'puppetdb::server::database_ini':
    database          => $database,
    database_host     => $database_host,
    database_port     => $database_port,
    database_username => $database_username,
    database_password => $database_password,
    database_name     => $database_name,
    confdir           => $confdir,
    notify            => Service['puppetdb'],
  }

  class { 'puppetdb::server::jetty_ini':
    ssl_listen_address  => $ssl_listen_address,
    ssl_listen_port     => $ssl_listen_port,
    listen_port         => $listen_port,
    confdir             => $confdir,
    notify              => Service['puppetdb'],
  }

  service { 'puppetdb':
    ensure => running,
    enable => true,
  }

  exec {'puppetdb-ssl-setup':
    path => "/usr/bin:/usr/sbin:/bin:/sbin",
    command => 'puppetdb-ssl-setup',
    require => [Package['puppetdb']],
    notify => [Service['puppetdb']],

  }
  Package['puppetdb'] ->
  Class['puppetdb::server::firewall'] ->
  Class['puppetdb::server::database_ini'] ->
  Class['puppetdb::server::jetty_ini'] ->
  Exec['puppetdb-ssl-setup'] ->
  Service['puppetdb']
}
