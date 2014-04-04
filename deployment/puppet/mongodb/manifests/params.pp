class mongodb::params{
  case $::osfamily {
    'redhat': {
      $baseurl = "http://downloads-distro.mongodb.org/repo/redhat/os/${::architecture}"
      $source  = 'mongodb::sources::yum'
      $package = 'mongodb-server'
      $service = 'mongod'
      $pkg_10gen = 'mongo-10gen-server'

      $mongo_user_10gen = 'mongod'
      $mongo_group_10gen = 'mongod'

      $config_path_10gen = '/etc/mongod.conf'

      $default_dbpath      = '/var/lib/mongodb'
      $default_logpath     = '/var/log/mongodb/mongodb.log'
      $default_pidfilepath = '/var/run/mongodb/mongodb.pid'
      $default_bind_ip     = '127.0.0.1'
      $default_fork        = true
      $default_journal     = true

      $default_dbpath_10gen      = '/var/lib/mongo'
      $default_logpath_10gen     = '/var/log/mongo/mongod.log'
      $default_pidfilepath_10gen = '/var/run/mongodb/mongod.pid'
      $default_bind_ip_10gen     = undef
      $default_fork_10gen        = true
      $default_journal_10gen     = undef
    }
    'debian': {
      $locations = {
        'sysv'    => 'http://downloads-distro.mongodb.org/repo/debian-sysvinit',
        'upstart' => 'http://downloads-distro.mongodb.org/repo/ubuntu-upstart'
      }
      case $::operatingsystem {
        'Debian': { $init = 'sysv' }
        'Ubuntu': { $init = 'upstart' }
      }
      $source  = 'mongodb::sources::apt'
      $package = 'mongodb'
      $service = 'mongodb'
      $pkg_10gen = 'mongodb-10gen'

      $mongo_user_10gen = 'mongodb'
      $mongo_group_10gen = 'mongodb'

      $config_path_10gen = '/etc/mongodb.conf'

      $default_dbpath      = '/var/lib/mongodb'
      $default_logpath     = '/var/log/mongodb/mongodb.log'
      $default_pidfilepath = undef
      $default_bind_ip     = '127.0.0.1'
      $default_fork        = undef
      $default_journal     = true

      $default_dbpath_10gen      = '/var/lib/mongodb'
      $default_logpath_10gen     = '/var/log/mongodb/mongodb.log'
      $default_pidfilepath_10gen = undef
      $default_bind_ip_10gen     = undef
      $default_fork_10gen        = undef
      $default_journal_10gen     = undef
    }
    default: {
      fail ("mongodb: ${::operatingsystem} is not supported.")
    }
  }

  $mongo_user_os = 'mongodb'
  $mongo_group_os = 'mongodb'

  $dbpath_os = '/var/lib/mongodb/'

  $logpath_os = '/var/log/mongodb/mongodb.log'
}
