#
# Class to execute "keystone-manage db_sync
#
class keystone::db::sync {
  exec { 'keystone-manage db_sync':
    path        => '/usr/bin',
    user        => 'keystone',
    refreshonly => true,
    subscribe   => [Package['keystone'], Keystone_config['sql/connection']],
    require     => User['keystone'],
  }
}
