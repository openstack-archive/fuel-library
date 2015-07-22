#
class cinder::db::sync {

  include ::cinder::params

  exec { 'cinder-manage db_sync':
    command     => $::cinder::params::db_sync_command,
    path        => '/usr/bin',
    user        => 'cinder',
    refreshonly => true,
    require     => Class['cinder'],
    logoutput   => 'on_failure',
  }
}
