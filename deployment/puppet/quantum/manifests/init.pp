#
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional.
# [syslog_log_level] logging level for non verbose and non debug mode. Optional.
#
class quantum (
  $quantum_config = {},
  $enabled              = true,
  $verbose              = 'False',
  $debug                = 'False',
  $core_plugin          = 'quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2',
  $auth_strategy        = 'keystone',
  $log_file             = '/var/log/quantum/server.log',
  $log_dir              = '/var/log/quantum',
  $use_syslog           = false,
  $syslog_log_facility  = 'LOCAL4',
  $syslog_log_level     = 'WARNING',
  $server_ha_mode       = false,
) {
  include 'quantum::params'

  anchor {'quantum-init':}

  if ! defined(File['/etc/quantum']) {
    file {'/etc/quantum':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => 755,
      #require => Package['quantum']
    }
  }

  package {'quantum':
    name   => $::quantum::params::package_name,
    ensure => present
  }

  file {'q-agent-cleanup.py':
    path   => '/usr/bin/q-agent-cleanup.py',
    mode   => 755,
    owner  => root,
    group  => root,
    source => "puppet:///modules/quantum/q-agent-cleanup.py",
  }

  file {'quantum-root':
    path => '/etc/sudoers.d/quantum-root',
    mode => 600,
    owner => root,
    group => root,
    source => "puppet:///modules/quantum/quantum-root",
    before => Package['quantum'],
  }

  file {'/var/cache/quantum':
    ensure  => directory,
    path   => '/var/cache/quantum',
    mode   => 755,
    owner  => quantum,
    group  => quantum,
  }
  case $quantum_config['amqp']['provider'] {
    'rabbitmq': {
        quantum_config {
          'DEFAULT/rpc_backend':          value => 'quantum.openstack.common.rpc.impl_kombu';
          'DEFAULT/rabbit_userid':        value => $quantum_config['amqp']['username'];
          'DEFAULT/rabbit_password':      value => $quantum_config['amqp']['passwd'];
          'DEFAULT/rabbit_virtual_host':  value => $quantum_config['amqp']['rabbit_virtual_host'];
        }
        if $quantum_config['amqp']['ha_mode'] {
            quantum_config {
              'DEFAULT/rabbit_ha_queues': value => 'True';
              'DEFAULT/rabbit_hosts':     value => $quantum_config['amqp']['hosts'];
              'DEFAULT/rabbit_host':     ensure => absent;
              'DEFAULT/rabbit_port':     ensure => absent;
            }
        } else {
            quantum_config {
              'DEFAULT/rabbit_ha_queues': value => 'False';
              'DEFAULT/rabbit_hosts':    ensure => absent;
              'DEFAULT/rabbit_host':      value => $quantum_config['amqp']['hosts'];
              'DEFAULT/rabbit_port':      value => $quantum_config['amqp']['port'];
            }
        }
    }
    'qpid', 'qpid-rh': {
        quantum_config {
          'DEFAULT/rpc_backend':   value => 'quantum.openstack.common.rpc.impl_qpid';
          'DEFAULT/qpid_hosts':    value => $quantum_config['amqp']['hosts'];
          'DEFAULT/qpid_port':     value => $quantum_config['amqp']['port'];
          'DEFAULT/qpid_username': value => $quantum_config['amqp']['username'];
          'DEFAULT/qpid_password': value => $quantum_config['amqp']['passwd'];
        }
    }
  }

  quantum_config {
    'DEFAULT/verbose':                value => $verbose;
    'DEFAULT/debug':                  value => $debug;
    'DEFAULT/auth_strategy':          value => $auth_strategy;
    'DEFAULT/core_plugin':            value => $core_plugin;
    'DEFAULT/bind_host':              value => $quantum_config['server']['bind_host'];
    'DEFAULT/bind_port':              value => $quantum_config['server']['bind_port'];
    'DEFAULT/base_mac':               value => $quantum_config['L2']['base_mac'];
    'DEFAULT/mac_generation_retries': value => $quantum_config['L2']['mac_generation_retries'];
    'DEFAULT/dhcp_lease_duration':    value => $quantum_config['L3']['dhcp_agent']['lease_duration'];
    'DEFAULT/allow_bulk':             value => $quantum_config['server']['allow_bulk'];
    'DEFAULT/allow_overlapping_ips':  value => $quantum_config['L3']['allow_overlapping_ips'];
    'DEFAULT/control_exchange':       value => $quantum_config['server']['control_exchange'];
    'DEFAULT/network_auto_schedule':  value => $quantum_config['L3']['network_auto_schedule'];
    'DEFAULT/router_auto_schedule':   value => $quantum_config['L3']['router_auto_schedule'];
    'DEFAULT/agent_down_time':        value => $quantum_config['server']['agent_down_time'];
    'keystone_authtoken/auth_host':         value => $quantum_config['keystone']['auth_host'];
    'keystone_authtoken/auth_port':         value => $quantum_config['keystone']['auth_port'];
    'keystone_authtoken/auth_url':          value => $quantum_config['keystone']['auth_url'];
    'keystone_authtoken/admin_tenant_name': value => $quantum_config['keystone']['admin_tenant_name'];
    'keystone_authtoken/admin_user':        value => $quantum_config['keystone']['admin_user'];
    'keystone_authtoken/admin_password':    value => $quantum_config['keystone']['admin_password'];
  }
  # logging for agents grabbing from stderr. It's workarround for bug in quantum-logging
  # server givs this parameters from command line
  # FIXME change init.d scripts for q&agents, fix daemon launch commands (CENTOS/RHEL):
  # quantum-server:
  #	daemon --user quantum --pidfile $pidfile "$exec --config-file $config --config-file /etc/$prog/plugin.ini &>>/var/log/quantum/server.log & echo \$!
  # quantum-ovs-cleanup:
  # 	daemon --user quantum $exec --config-file /etc/$proj/$proj.conf --config-file $config &>>/var/log/$proj/$plugin.log
  # quantum-ovs/metadata/l3/dhcp/-agents:
  # 	daemon --user quantum --pidfile $pidfile "$exec --config-file /etc/$proj/$proj.conf --config-file $config &>>/var/log/$proj/$plugin.log & echo \$! > $pidfile"

  quantum_config {
      'DEFAULT/log_file':   ensure=> absent;
      'DEFAULT/logfile':    ensure=> absent;
  }
  if $use_syslog and !$debug =~ /(?i)(true|yes)/ {
    quantum_config {
        'DEFAULT/log_dir':    ensure=> absent;
        'DEFAULT/logdir':     ensure=> absent;
        'DEFAULT/log_config':   value => "/etc/quantum/logging.conf";
        'DEFAULT/use_stderr': ensure=> absent;
        'DEFAULT/use_syslog': value=> true;
        'DEFAULT/syslog_log_facility': value=> $syslog_log_facility;
    }
    file { "quantum-logging.conf":
      content => template('quantum/logging.conf.erb'),
      path  => "/etc/quantum/logging.conf",
      owner => "root",
      group => "quantum",
      mode  => 640,
    }
  } else {
    quantum_config {
    # logging for agents grabbing from stderr. It's workarround for bug in quantum-logging
      'DEFAULT/use_syslog': ensure=> absent;
      'DEFAULT/syslog_log_facility': ensure=> absent;
      'DEFAULT/log_config': ensure=> absent;
      # FIXME stderr should not be used unless quantum+agents init & OCF scripts would be fixed to redirect its output to stderr!
      #'DEFAULT/use_stderr': value => true;
      'DEFAULT/use_stderr': ensure=> absent;
      'DEFAULT/log_dir': value => $log_dir;
    }
    file { "quantum-logging.conf":
      content => template('quantum/logging.conf-nosyslog.erb'),
      path  => "/etc/quantum/logging.conf",
      owner => "root",
      group => "quantum",
      mode  => 640,
    }
  }
  # We must setup logging before start services under pacemaker
  File['quantum-logging.conf'] -> Service<| title == "$::quantum::params::server_service" |>
  File['quantum-logging.conf'] -> Anchor<| title == 'quantum-ovs-agent' |>
  File['quantum-logging.conf'] -> Anchor<| title == 'quantum-l3' |>
  File['quantum-logging.conf'] -> Anchor<| title == 'quantum-dhcp-agent' |>
  File <| title=='/etc/quantum' |> -> File <| title=='quantum-logging.conf' |>

  if defined(Anchor['quantum-server-config-done']) {
    $endpoint_quantum_main_configuration = 'quantum-server-config-done'
  } else {
    $endpoint_quantum_main_configuration = 'quantum-init-done'
  }

  # FIXME Workaround for FUEL-842: remove explicit --log-config from init scripts cuz it breaks logging!
  # FIXME this hack should be deleted after FUEL-842 have resolved
  exec {'init-dirty-hack':
    command => "sed -i 's/\-\-log\-config=\$loggingconf//g' /etc/init.d/quantum-*",
    path    => ["/sbin", "/bin", "/usr/sbin", "/usr/bin"],
  }

  Anchor['quantum-init'] ->
    Package['quantum'] ->
     Exec['init-dirty-hack'] ->
      File['/var/cache/quantum'] ->
        Quantum_config<||> ->
          Quantum_api_config<||> ->
            Anchor[$endpoint_quantum_main_configuration]

  anchor {'quantum-init-done':}
}

# vim: set ts=2 sw=2 et :