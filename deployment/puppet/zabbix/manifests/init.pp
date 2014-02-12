# == Class: zabbix
#
# Install and configure zabbix agent on a system. This class is part of
# our default setup, we install the zabbix agent on every machine and
# configure it to send info to the server on a regular base. This is
# simply a classic active zabbix agent setup.
#
# See zabbix::params for a list of supported operating systems.
#
class zabbix {
  if $::fuel_settings['zabbix']['enabled'] == true {

    if $::fuel_settings['role'] == 'zabbix-server' {
      class { 'zabbix::server': } ->
      class { 'zabbix::monitoring': }
    } else {
      class { 'zabbix::monitoring': }
    }
  }
}
