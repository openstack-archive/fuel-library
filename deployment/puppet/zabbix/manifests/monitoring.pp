class zabbix::monitoring inherits zabbix::params {

  anchor { 'zabbix_agent_start': } ->
  class { 'zabbix::agent': } ->
  anchor { 'zabbix_agent_end': }

  anchor { 'zabbix_agent_scripts_start': } ->
  class { 'zabbix::agent::scripts': } ->
  anchor { 'zabbix_agent_scripts_end': }

  ####

  Anchor['zabbix_agent_scripts_end'] ->
  Anchor['monitoring-registration-start']

  Anchor['monitoring-registration-end'] ->
  Anchor['zabbix_agent_start']

  # Auto-registration

  anchor{ 'monitoring-registration-start' :}
  anchor{ 'monitoring-registration-end' :}

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::ceilometer_compute' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::ceilometer_controller' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::ceph' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::cinder' :} ->
  Anchor['monitoring-registration-end']

  # (TODO) uncomment this after iptstate will added to repos
  # Anchor['monitoring-registration-start'] ->
  # class { 'zabbix::monitoring::firewall' :} ->
  # Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::glance' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::haproxy' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::horizon' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::keystone' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::memcached' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::mysql' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::neutron_agents' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::neutron_server' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::nova_compute' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::nova_controller' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::openstack_virtual' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::openvswitch' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::rabbitmq' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::swift' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::zabbix_server' :} ->
  Anchor['monitoring-registration-end']

  Anchor['monitoring-registration-start'] ->
  class { 'zabbix::monitoring::zabbix_agent' :} ->
  Anchor['monitoring-registration-end']

}
