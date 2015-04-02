class zabbix::monitoring inherits zabbix::params {

  zabbix_usermacro { "${host_name} IP_PUBLIC":
    host  => $host_name,
    macro => '{$IP_PUBLIC}',
    value => $public_address,
    api   => $api_hash,
  }

  zabbix_usermacro { "${host_name} IP_MANAGEMENT":
    host  => $host_name,
    macro => '{$IP_MANAGEMENT}',
    value => $internal_address,
    api   => $api_hash,
  }

  zabbix_usermacro { "${host_name} IP_STORAGE":
    host  => $host_name,
    macro => '{$IP_STORAGE}',
    value => $storage_address,
    api   => $api_hash,
  }

  Anchor<| title == 'zabbix_agent_end' |> -> Anchor<| title == 'zabbix_agent_scripts_begin' |>

  class { 'zabbix::agent': }
  anchor { 'zabbix_agent_begin': } ->
  Class['zabbix::agent'] ->
  anchor { 'zabbix_agent_end': }

  class { 'zabbix::agent::scripts': }
  anchor { 'zabbix_agent_scripts_begin': } ->
  Class['zabbix::agent::scripts'] ->
  anchor { 'zabbix_agent_scripts_end': }

  Class['zabbix::agent'] -> Zabbix_usermacro <||>
  Class['zabbix::agent'] -> Zabbix_template_link <||>

  # Auto-registration
  include zabbix::monitoring::ceilometer_compute
  include zabbix::monitoring::ceilometer_controller
  include zabbix::monitoring::ceph
  include zabbix::monitoring::cinder
  # (TODO) uncomment this after iptstate will added to repos
  #include zabbix::monitoring::firewall
  include zabbix::monitoring::glance
  include zabbix::monitoring::haproxy
  include zabbix::monitoring::horizon
  include zabbix::monitoring::keystone
  include zabbix::monitoring::memcached
  include zabbix::monitoring::mysql
  include zabbix::monitoring::neutron_agents
  include zabbix::monitoring::neutron_server
  include zabbix::monitoring::nova_compute
  include zabbix::monitoring::nova_controller
  include zabbix::monitoring::openstack_virtual
  include zabbix::monitoring::openvswitch
  include zabbix::monitoring::rabbitmq
  include zabbix::monitoring::swift
  include zabbix::monitoring::zabbix_server
  include zabbix::monitoring::zabbix_agent
}
