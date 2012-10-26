# Class: puppetdb
#
# This class provides a simple way to get a puppetdb instance up and running
# with minimal effort.  It will install and configure all necessary packages,
# including the database server and instance.
#
# This class is intended as a high-level abstraction to help simplify the process
# of getting your puppetdb server up and running; it wraps the slightly-lower-level
# classes `puppetdb::server` and `puppetdb::database::*`.  For maximum
# configurability, you may choose not to use this class.  You may prefer to
# use the `puppetdb::server` class directly, or manage your puppetdb setup on your
# own.
#
# In addition to this class, you'll need to configure your puppet master to use
# puppetdb.  You can use the `puppetdb::master::config` class to accomplish this.
#
# Parameters:
#   ['database'] - Which database backend to use; legal values are
#                  `postgres` (default) or `embedded`.  (The `embedded`
#                  db can be used for very small installations or for
#                  testing, but is not recommended for use in production
#                  environments.  For more info, see the puppetdb docs.)
#   ['puppetdb_version']   - The version of the `puppetdb` package that should
#                  be installed.  You may specify an explicit version
#                  number, 'present', or 'latest'.  Defaults to
#                  'present'.
#
# Actions:
# - Creates and manages a puppetdb server and its database server/instance.
#
# Requires:
# - `inkling/postgresql`
#
# Sample Usage:
#   include puppetdb
#
#
# TODO: expose more parameters
#
class puppetdb(
  $database               = $puppetdb::params::database,
  $puppetdb_version       = $puppetdb::params::puppetdb_version,
) inherits puppetdb::params {

  class { 'puppetdb::server':
    database               => $database,
    puppetdb_version       => $puppetdb_version,
  }

  if ($database == 'postgres') {
    class { 'puppetdb::database::postgresql':
      before                 => Class['puppetdb::server']
    }
  }
}
