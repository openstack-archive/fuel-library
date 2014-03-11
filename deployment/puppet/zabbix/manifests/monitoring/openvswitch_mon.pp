class zabbix::monitoring::openvswitch_mon {

  include zabbix::params

  # Open vSwitch

  zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Open vSwitch":
    host => $zabbix::params::host_name,
    template => 'Template App OpenStack Open vSwitch',
    api => $zabbix::params::api_hash,
  }
}
