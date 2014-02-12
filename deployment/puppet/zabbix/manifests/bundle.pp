# == Class: zabbix::bundle
#
# installs a zabbixized puppet module on both zabbix server and client
#
# Must only be included on the client.
#
# === Parameters
# [*ensure*]
#  present or absent, present is default
# [*items*]
#  hash of items to add to bundle
#
# === Example Usage
#
class zabbix::bundle (
  $ensure = 'present',
  $items  = {
  }
) inherits zabbix::params {
  $ensure_real = $ensure

  @@zabbix::server::template { $name:
    ensure => $ensure_real
  }

  # do once per items
  zabbix::agent::param { $items[name]:
    ensure => $ensure_real,
    key    => $items[key]
  }

}
