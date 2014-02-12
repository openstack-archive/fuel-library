# == Class: zabbix::api
#
# Install and manage a zabbix library. It enables you to use zabbix in puppet.
#
# === Parameters
# [*ensure*]
#  present, absent to use package manager or false to disable package resource
# [*url*]
#  url for the zabbix jsonrpc api
# [*username*]
#  zabbix password for the server
# [*password*]
#  zabbix password for the server
# [*http_username*]
#  http password for the server
# [*http_password*]
#  http password for the server
# [*api_debug*]
#  should we enable debug messages
#
# === Issues
#
# * only really tested on some debian flavors
#
class zabbix::api {
  
  include zabbix::params
  
  file { '/etc/puppet/zabbix.api.yaml':
    content => template('zabbix/zabbix.api.yaml.erb'),
    mode    => '0440',
    owner   => 'zabbix',
    group   => 'puppet',
  }

  #ensure the configuration file is enabled before we use the api
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_api <| |>
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_host <| |>
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_host_interface <| |>
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_hostgroup <| |>
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_mediatype <| |>
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_template <| |>
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_template_application <| |>
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_template_item <| |>
  File['/etc/puppet/zabbix.api.yaml'] -> Zabbix_trigger <| |>

  $gem_server = $base_syslog_hash['syslog_server']
}

