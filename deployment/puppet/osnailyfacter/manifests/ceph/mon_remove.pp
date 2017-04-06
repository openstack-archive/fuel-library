# == Define Resource Type: osnailyfacter::ceph::mon_remove
#
# Removes ceph monitor with given hostname.
#
# === Parameters
#
# [*name*]
#   The namevar of the defined resource type is the hostname
#   or fqdn of ceph monitor which will be removed from pool.
#

define osnailyfacter::ceph::mon_remove (
) {

  # get hostname of monitor
  $monitor_name = delete($name, ".${::domain}")

  exec { "ceph mon rm ${monitor_name}":
    path      => ['/bin', '/usr/bin'],
    onlyif    => "ceph mon dump | fgrep -qw mon.${monitor_name}",
    logoutput => true,
  }

}

