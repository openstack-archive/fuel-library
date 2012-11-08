# Class: puppetdb::server::database_ini
#
# This class manages puppetdb's `database.ini` file.
#
# Parameters:
#   ['database']        - Which database backend to use; legal values are
#                         `postgres` (default) or `embedded`.  (The `embedded`
#                         db can be used for very small installations or for
#                         testing, but is not recommended for use in production
#                         environments.  For more info, see the puppetdb docs.)
#   ['database_host']   - The hostname or IP address of the database server.
#                         (defaults to `localhost`; ignored for `embedded` db)
#   ['database_port']   - The port that the database server listens on.
#                         (defaults to `5432`; ignored for `embedded` db)
#   ['database_user']   - The name of the database user to connect as.
#                         (defaults to `puppetdb`; ignored for `embedded` db)
#   ['database_password'] - The password for the database user.
#                         (defaults to `puppetdb`; ignored for `embedded` db)
#   ['database_name']   - The name of the database instance to connect to.
#                         (defaults to `puppetdb`; ignored for `embedded` db)
#   ['confdir']         - The puppetdb configuration directory; defaults to
#                         `/etc/puppetdb/conf.d`.
#
# Actions:
# - Manages puppetdb's `database.ini` file
#
# Requires:
# - Inifile
#
# Sample Usage:
#   class { 'puppetdb::server::database_ini':
#     database_host     => 'my.postgres.host',
#     database_port     => '5432',
#     database_username => 'puppetdb_pguser',
#     database_password => 'puppetdb_pgpasswd',
#     database_name     => 'puppetdb',
#   }
#
class puppetdb::server::database_ini(
  $database          = $puppetdb::params::database,
  $database_host     = $puppetdb::params::database_host,
  $database_port     = $puppetdb::params::database_port,
  $database_username = $puppetdb::params::database_username,
  $database_password = $puppetdb::params::database_password,
  $database_name     = $puppetdb::params::database_name,
  $confdir           = $puppetdb::params::confdir,
) inherits puppetdb::params {

  # Validate the database connection.  If we can't connect, we want to fail
  # and skip the rest of the configuration, so that we don't leave puppetdb
  # in a broken state.
  class { 'puppetdb::server::validate_db':
    database          => $database,
    database_host     => $database_host,
    database_port     => $database_port,
    database_username => $database_username,
    database_password => $database_password,
    database_name     => $database_name,
  }

  #Set the defaults
  Ini_setting {
    path    => "${confdir}/database.ini",
    ensure  => present,
    section => 'database',
    require => Class['puppetdb::server::validate_db'],
  }

  if $database == 'embedded'{

    $classname   = 'org.hsqldb.jdbcDriver'
    $subprotocol = 'hsqldb'
    $subname     = 'file:/usr/share/puppetdb/db/db;hsqldb.tx=mvcc;sql.syntax_pgs=true'

  } elsif $database == 'postgres' {
    $classname = 'org.postgresql.Driver'
    $subprotocol = 'postgresql'
    $subname = "//${database_host}:${database_port}/${database_name}"

    ##Only setup for postgres
    ini_setting {'puppetdb_psdatabase_username':
      setting => 'username',
      value   => $database_username,
    }

    ini_setting {'puppetdb_psdatabase_password':
      setting => 'password',
      value   => $database_password,
    }
  }

  ini_setting {'puppetdb_classname':
    setting => 'classname',
    value   => $classname,
  }

  ini_setting {'puppetdb_subprotocol':
    setting => 'subprotocol',
    value   => $subprotocol,
  }

  ini_setting {'puppetdb_pgs':
    setting => 'syntax_pgs',
    value   => true,
  }

  ini_setting {'puppetdb_subname':
    setting => 'subname',
    value   => $subname,
  }

  ini_setting {'puppetdb_gc_interval':
    setting => 'gc-interval',
    value   => $puppetdb::params::gc_interval,
  }
}
