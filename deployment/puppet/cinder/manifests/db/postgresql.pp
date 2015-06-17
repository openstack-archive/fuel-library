#
# Class that configures postgresql for cinder
#
# Requires the Puppetlabs postgresql module.
class cinder::db::postgresql(
  $password,
  $dbname = 'cinder',
  $user   = 'cinder'
) {

  require postgresql::python

  Postgresql::Db[$dbname]    ~> Exec<| title == 'cinder-manage db_sync' |>
  Package['python-psycopg2'] -> Exec<| title == 'cinder-manage db_sync' |>

  postgresql::db { $dbname:
    user      =>  $user,
    password  =>  $password,
  }

}
