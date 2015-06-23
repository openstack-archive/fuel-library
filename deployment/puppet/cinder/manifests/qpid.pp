# == Class: cinder::qpid
#
# class for installing qpid server for cinder
#
# === Parameters
#
# [*enabled*]
#   (Optional) Whether to enable the qpid service.
#   Defaults to 'true'.
#
# [*user*]
#   (Optional) The username to use when connecting to qpid.
#   Defaults to 'guest'.
#
# [*password*]
#   (Optional) The password to use when connecting to qpid
#   Defaults to 'guest'.
#
# [*file*]
#   (Optional) The SASL database.
#   Defaults to '/var/lib/qpidd/qpidd.sasldb'.
#
# [*realm*]
#   (Optional) The Realm for qpid.
#   Defaults to 'OPENSTACK'.
#
#
class cinder::qpid (
  $enabled  = true,
  $user     ='guest',
  $password ='guest',
  $file     ='/var/lib/qpidd/qpidd.sasldb',
  $realm    ='OPENSTACK'
) {

  # only configure cinder after the queue is up
  Class['qpid::server'] -> Package<| title == 'cinder' |>

  if ($enabled) {
    $service_ensure = 'running'

    qpid_user { $user:
      password => $password,
      file     => $file,
      realm    => $realm,
      provider => 'saslpasswd2',
      require  => Class['qpid::server'],
    }

  } else {
    $service_ensure = 'stopped'
  }

  class { '::qpid::server':
    service_ensure => $service_ensure
  }

}
