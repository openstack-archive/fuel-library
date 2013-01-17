# Class: puppetdb::server::jetty_ini
#
# This class manages puppetdb's `jetty.ini` file, which contains the configuration
# for puppetdb's embedded web server.
#
# Parameters:
#   ['ssl_listen_address'] - The address that the web server should bind to
#                            for HTTPS requests.  (defaults to `$::clientcert`.)
#   ['ssl_listen_port']    - The port on which the puppetdb web server should
#                            accept HTTPS requests.
#   ['database_name']   - The name of the database instance to connect to.
#                         (defaults to `puppetdb`; ignored for `embedded` db)
#   ['confdir']         - The puppetdb configuration directory; defaults to
#                         `/etc/puppetdb/conf.d`.
#
# Actions:
# - Manages puppetdb's `jetty.ini` file
#
# Requires:
# - Inifile
#
# Sample Usage:
#   class { 'puppetdb::server::jetty_ini':
#       ssl_listen_address      => 'my.https.interface.hostname',
#       ssl_listen_port         => 8081,
#   }
#
#TODO add support for non-ssl config
#
class puppetdb::server::jetty_ini(
  $ssl_listen_address = $puppetdb::params::ssl_listen_address,
  $ssl_listen_port    = $puppetdb::params::ssl_listen_port,
  $listen_port        = $puppetdb::params::listen_port,
  $confdir            = $puppetdb::params::confdir,
) inherits puppetdb::params {

  #Set the defaults
  Ini_setting {
    path    => "${confdir}/jetty.ini",
    ensure  => present,
    section => 'jetty',
  }

  # TODO: figure out some way to make sure that the ini_file module is installed,
  #  because otherwise these will silently fail to do anything.

  ini_setting {'puppetdb_sslhost':
    setting => 'ssl-host',
    value   => $ssl_listen_address,
  }

  ini_setting {'puppetdb_port':
    setting => 'port',
    value   => $listen_port,
  }

  ini_setting {'puppetdb_sslport':
    setting => 'ssl-port',
    value   => $ssl_listen_port,
  }
}
