#
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional.
# [syslog_log_level] logging level for non verbose and non debug mode. Optional.
#
class neutron (
  $neutron_config = {},
  $enabled              = true,
  $verbose              = false,
  $debug                = false,
  $core_plugin          = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
  $auth_strategy        = 'keystone',
  $log_file             = '/var/log/neutron/server.log',
  $log_dir              = '/var/log/neutron',
  $use_syslog           = false,
  $syslog_log_facility  = 'LOG_LOCAL4',
  $syslog_log_level     = 'WARNING',
  $ssh_private_key      = '/var/lib/astute/neutron/neutron',
  $ssh_public_key       = '/var/lib/astute/neutron/neutron.pub',
  $server_ha_mode       = false,
) {
  include 'neutron::params'

  Anchor<| title == 'galera-done' |> ->
  anchor {'neutron-init':}

  if ! defined(File['/etc/neutron']) {
    file {'/etc/neutron':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
  }

  package {'neutron':
    name   => $::neutron::params::package_name,
    ensure => present
  }

  Package['neutron'] ->
  file {'q-agent-cleanup.py':
    path   => '/usr/bin/q-agent-cleanup.py',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => "puppet:///modules/neutron/q-agent-cleanup.py",
  }

  Package['neutron'] ->
  file {'neutron-root':
    path => '/etc/sudoers.d/neutron-root',
    mode => '0440',
    owner => root,
    group => root,
    source => "puppet:///modules/neutron/neutron-root",
  }

  Package['neutron'] ->
  file {'/var/cache/neutron':
    ensure  => directory,
    path   => '/var/cache/neutron',
    mode   => '0755',
    owner  => neutron,
    group  => neutron,
  }
  case $neutron_config['amqp']['provider'] {
    'rabbitmq': {
        neutron_config {
          'DEFAULT/rpc_backend':          value => 'neutron.openstack.common.rpc.impl_kombu';
          'DEFAULT/rabbit_userid':        value => $neutron_config['amqp']['username'];
          'DEFAULT/rabbit_password':      value => $neutron_config['amqp']['passwd'];
          'DEFAULT/rabbit_virtual_host':  value => $neutron_config['amqp']['rabbit_virtual_host'];
        }
        if $neutron_config['amqp']['ha_mode'] {
            neutron_config {
              'DEFAULT/rabbit_ha_queues': value => 'True';
              'DEFAULT/rabbit_hosts':     value => $neutron_config['amqp']['hosts'];
              'DEFAULT/rabbit_host':     ensure => absent;
              'DEFAULT/rabbit_port':     ensure => absent;
            }
        } else {
            neutron_config {
              'DEFAULT/rabbit_ha_queues': value => 'False';
              'DEFAULT/rabbit_hosts':    ensure => absent;
              'DEFAULT/rabbit_host':      value => $neutron_config['amqp']['hosts'];
              'DEFAULT/rabbit_port':      value => $neutron_config['amqp']['port'];
            }
        }
    }
    'qpid', 'qpid-rh': {
        neutron_config {
          'DEFAULT/rpc_backend':   value => 'neutron.openstack.common.rpc.impl_qpid';
          'DEFAULT/qpid_hosts':    value => $neutron_config['amqp']['hosts'];
          'DEFAULT/qpid_port':     value => $neutron_config['amqp']['port'];
          'DEFAULT/qpid_username': value => $neutron_config['amqp']['username'];
          'DEFAULT/qpid_password': value => $neutron_config['amqp']['passwd'];
        }
    }
  }

  if $server_ha_mode {
    $server_bind_host = $neutron_config['server']['bind_host']
  } else {
    $server_bind_host = '0.0.0.0'
  }

  neutron_config {
    'DEFAULT/debug':                  value => $debug;
    'DEFAULT/verbose':                value => $verbose;
    'DEFAULT/log_dir':               ensure => absent;
    'DEFAULT/log_file':              ensure => absent;
    'DEFAULT/log_config':            ensure => absent;
    #TODO(bogdando) fix syslog usage after Oslo logging patch synced in I.
    'DEFAULT/use_syslog':             value => false;
    'DEFAULT/use_stderr':             value => true;
    'DEFAULT/publish_errors':         value => false;
    'DEFAULT/auth_strategy':          value => $auth_strategy;
    'DEFAULT/core_plugin':            value => $core_plugin;
    'DEFAULT/bind_host':              value => $server_bind_host;
    'DEFAULT/bind_port':              value => $neutron_config['server']['bind_port'];
    'DEFAULT/base_mac':               value => $neutron_config['L2']['base_mac'];
    'DEFAULT/mac_generation_retries': value => $neutron_config['L2']['mac_generation_retries'];
    'DEFAULT/dhcp_lease_duration':    value => $neutron_config['L3']['dhcp_agent']['lease_duration'];
    'DEFAULT/allow_bulk':             value => $neutron_config['server']['allow_bulk'];
    'DEFAULT/allow_overlapping_ips':  value => $neutron_config['L3']['allow_overlapping_ips'];
    'DEFAULT/control_exchange':       value => $neutron_config['server']['control_exchange'];
    'DEFAULT/network_auto_schedule':  value => $neutron_config['L3']['network_auto_schedule'];
    'DEFAULT/router_auto_schedule':   value => $neutron_config['L3']['router_auto_schedule'];
    'DEFAULT/agent_down_time':        value => $neutron_config['server']['agent_down_time'];
    'DEFAULT/firewall_driver':        value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
    'agent/root_helper':              value => $neutron_config['root_helper'];
    'quota/quota_driver':             value => 'neutron.db.quota_db.DbQuotaDriver';
    'keystone_authtoken/auth_host':         value => $neutron_config['keystone']['auth_host'];
    'keystone_authtoken/auth_port':         value => $neutron_config['keystone']['auth_port'];
    'keystone_authtoken/auth_protocol':     value => $neutron_config['keystone']['auth_protocol'];
    'keystone_authtoken/auth_url':          value => $neutron_config['keystone']['auth_url'];
    'keystone_authtoken/admin_tenant_name': value => $neutron_config['keystone']['admin_tenant_name'];
    'keystone_authtoken/admin_user':        value => $neutron_config['keystone']['admin_user'];
    'keystone_authtoken/admin_password':    value => $neutron_config['keystone']['admin_password'];
  }

  if defined(Anchor['neutron-server-config-done']) {
    $endpoint_neutron_main_configuration = 'neutron-server-config-done'
  } else {
    $endpoint_neutron_main_configuration = 'neutron-init-done'
  }


  $fuel_utils_package = $neutron::params::fuel_utils_package
  package { $fuel_utils_package :
    ensure => installed,
  }

  install_ssh_keys {'neutron_ssh_key':
    ensure           => present,
    user             => 'root',
    private_key_path => $ssh_private_key,
    public_key_path  => $ssh_public_key,
    private_key_name => 'id_rsa_neutron',
    public_key_name  => 'id_rsa_neutron.pub',
    authorized_keys  => 'authorized_keys',
  }

  Anchor['neutron-init'] -> Package[$fuel_utils_package] -> Install_ssh_keys['neutron_ssh_key'] -> Anchor[$endpoint_neutron_main_configuration]


  Anchor['neutron-init'] ->
    Package['neutron'] ->
      File['/var/cache/neutron'] ->
        Neutron_config<||> ->
          Neutron_api_config<||> ->
            Anchor[$endpoint_neutron_main_configuration]

  anchor {'neutron-init-done':}
}

