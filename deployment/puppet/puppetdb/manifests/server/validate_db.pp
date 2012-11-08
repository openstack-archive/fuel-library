# Class: puppetdb::server::validate_db
#
# This type validates that a successful database connection can be established
# between the node on which this resource is run and the specified puppetdb
# database instance (host/port/user/password/database name).
#
# Parameters:
#   [*database*]            - Which database backend to use; legal values are
#                             `postgres` (default) or `embedded`.  There is no
#                             validation for the `embedded` database, so the
#                             rest of the parameters will be ignored in that
#                             case.  (The `embedded` db can be used for very small
#                             installations or for testing, but is not recommended
#                             for use in production environments.  For more info,
#                             see the puppetdb docs.)
#   [*database_host*]       - the hostname or IP address of the machine where the
#                             postgres server should be running.
#   [*database_port*]       - the port on which postgres server should be
#                             listening (defaults to 5432).
#   [*database_username*]   - the postgres username
#   [*database_password*]   - the postgres user's password
#   [*database_name*]       - the database name that the connection should be
#                             established against
#
# Actions:
#
# Attempts to establish a connection to the specified puppetdb database.  If
#  a connection cannot be established, the resource will fail; this allows you
#  to use it as a dependency for other resources that would be negatively
#  impacted if they were applied without the postgres connection being available.
#
# Requires:
#
#  `inkling/postgresql`
#
# Sample Usage:
#
#  puppetdb::server::validate_db { 'validate my puppetdb database connection':
#      database_host           => 'my.postgres.host',
#      database_username       => 'mydbuser',
#      database_password       => 'mydbpassword',
#      database_name           => 'mydbname',
#  }
#
class puppetdb::server::validate_db(
  $database          = $puppetdb::params::database,
  $database_host     = $puppetdb::params::database_host,
  $database_port     = $puppetdb::params::database_port,
  $database_username = $puppetdb::params::database_username,
  $database_password = $puppetdb::params::database_password,
  $database_name     = $puppetdb::params::database_name
) inherits puppetdb::params {

  # We don't need any validation for the embedded database, presumably.
  if ($database == 'postgres') {
    ::postgresql::validate_db_connection { 'validate puppetdb postgres connection':
      database_host     => $database_host,
      database_port     => $database_port,
      database_username => $database_username,
      database_password => $database_password,
      database_name     => $database_name,
    }
  }
}
