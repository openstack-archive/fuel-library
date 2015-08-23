# == Type: openstack::ha::haproxy_restart
#
#  This class contains Exec['haproxy-restart'] that can be used to restart
#  haproxy via the ocf script
#
#  We are leveraging this class and exec so that it can be included anywhere
#  that might want to notify haproxy to restart.  To trigger the restart of
#  haproxy, one simply needs to do a notify to Exec['haproxy-restart'] after
#  including this class.  Also by doing it this way, we ensure we only restart
#  when there is an actual configuration change.
#
# === Parameters
#
#  None.
#
# === Example
#
#  include openstack::ha::haproxy_restart
#  haproxy::listen { 'myvip':
#    order     => '010',
#    ipaddress => $::ipaddress,
#    ports     => '8888',
#    mode      => 'tcp',
#    notify    => Exec['haproxy-restart']
#  }
#
class openstack::ha::haproxy_restart {
  exec { 'haproxy-restart':
    command     => '/usr/lib/ocf/resource.d/fuel/ns_haproxy reload',
    environment => ['OCF_ROOT=/usr/lib/ocf'],
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    logoutput   => true,
    provider    => 'shell',
    tries       => 10,
    try_sleep   => 10,
    returns     => [0, ''],
    refreshonly => true,
  }
}
