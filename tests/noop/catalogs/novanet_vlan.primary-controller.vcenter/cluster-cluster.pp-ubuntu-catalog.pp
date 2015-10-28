anchor { 'corosync-done':
  name => 'corosync-done',
}

anchor { 'corosync':
  before => ['Cs_property[no-quorum-policy]', 'Cs_property[stonith-enabled]', 'Cs_property[start-failure-is-fatal]', 'Cs_property[symmetric-cluster]', 'Corosync::Service[pacemaker]'],
  name   => 'corosync',
}

class { 'Cluster':
  corosync_nodes   => {'node-3.test.domain.local' => {'id' => '3', 'ip' => '172.16.1.5'}, 'node-5.test.domain.local' => {'id' => '5', 'ip' => '172.16.1.6'}, 'node-6.test.domain.local' => {'id' => '6', 'ip' => '172.16.1.3'}},
  internal_address => '172.16.1.5',
  name             => 'Cluster',
}

class { 'Corosync::Params':
  name => 'Corosync::Params',
}

class { 'Corosync':
  authkey           => '/etc/puppet/ssl/certs/ca.pem',
  authkey_source    => 'file',
  before            => ['Cs_property[no-quorum-policy]', 'Cs_property[stonith-enabled]', 'Cs_property[start-failure-is-fatal]', 'Cs_property[symmetric-cluster]', 'Anchor[corosync-done]'],
  bind_address      => '172.16.1.5',
  check_standby     => 'false',
  corosync_nodes    => {'node-3.test.domain.local' => {'id' => '3', 'ip' => '172.16.1.5'}, 'node-5.test.domain.local' => {'id' => '5', 'ip' => '172.16.1.6'}, 'node-6.test.domain.local' => {'id' => '6', 'ip' => '172.16.1.3'}},
  corosync_version  => '2',
  debug             => 'false',
  enable_secauth    => 'false',
  force_online      => 'false',
  multicast_address => '239.1.1.2',
  name              => 'Corosync',
  packages          => ['corosync', 'pacemaker', 'crmsh', 'pcs'],
  port              => '5405',
  rrp_mode          => 'none',
  threads           => '4',
  ttl               => 'false',
}

class { 'Openstack::Corosync':
  bind_address          => '172.16.1.5',
  corosync_nodes        => {'node-3.test.domain.local' => {'id' => '3', 'ip' => '172.16.1.5'}, 'node-5.test.domain.local' => {'id' => '5', 'ip' => '172.16.1.6'}, 'node-6.test.domain.local' => {'id' => '6', 'ip' => '172.16.1.3'}},
  corosync_version      => '2',
  expected_quorum_votes => '2',
  multicast_address     => '239.1.1.2',
  name                  => 'Openstack::Corosync',
  packages              => ['corosync', 'pacemaker', 'crmsh', 'pcs'],
  quorum_policy         => 'ignore',
  secauth               => 'false',
  stonith               => 'false',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

corosync::service { 'pacemaker':
  before  => 'Anchor[corosync-done]',
  name    => 'pacemaker',
  notify  => 'Service[corosync]',
  version => '1',
}

cs_property { 'no-quorum-policy':
  ensure   => 'present',
  before   => ['Cs_property[stonith-enabled]', 'Anchor[corosync-done]'],
  name     => 'no-quorum-policy',
  provider => 'crm',
  value    => 'ignore',
}

cs_property { 'start-failure-is-fatal':
  ensure   => 'present',
  before   => 'Anchor[corosync-done]',
  name     => 'start-failure-is-fatal',
  provider => 'crm',
  value    => 'false',
}

cs_property { 'stonith-enabled':
  ensure   => 'present',
  before   => ['Cs_property[start-failure-is-fatal]', 'Anchor[corosync-done]'],
  name     => 'stonith-enabled',
  provider => 'crm',
  value    => 'false',
}

cs_property { 'symmetric-cluster':
  ensure   => 'present',
  before   => 'Anchor[corosync-done]',
  name     => 'symmetric-cluster',
  provider => 'crm',
  value    => 'false',
}

exec { 'enable corosync':
  before  => 'Service[corosync]',
  command => 'sed -i s/START=no/START=yes/ /etc/default/corosync',
  path    => ['/bin', '/usr/bin'],
  require => 'Package[corosync]',
  unless  => 'grep START=yes /etc/default/corosync',
}

file { '/etc/corosync/corosync.conf':
  ensure  => 'file',
  before  => ['Service[corosync]', 'File[/etc/corosync/uidgid.d/pacemaker]'],
  content => 'compatibility: whitetank

quorum {
  provider: corosync_votequorum
        two_node: 0
   }

nodelist {
  node {
    # node-5.test.domain.local
    ring0_addr: 172.16.1.6
    nodeid: 5
  }
  node {
    # node-6.test.domain.local
    ring0_addr: 172.16.1.3
    nodeid: 6
  }
  node {
    # node-3.test.domain.local
    ring0_addr: 172.16.1.5
    nodeid: 3
  }
}

totem {
  version:                             2
  token:                               3000
  token_retransmits_before_loss_const: 10
  join:                                60
  consensus:                           3600
  vsftype:                             none
  max_messages:                        20
  clear_node_high_bit:                 yes
  rrp_mode:                            none
  secauth:                             off
  threads:                             4
  transport:                           udpu
  interface {
    ringnumber:  0
    bindnetaddr: 172.16.1.5
    mcastport:   5405
  }
}

logging {
  fileline:        off
  to_stderr:       no
  to_logfile:      no
  logfile:         /var/log/corosync.log
  to_syslog:       yes
  syslog_facility: daemon
  syslog_priority: info
  debug:           off
  function_name:   on
  timestamp:       on
  logger_subsys {
    subsys: AMF
    debug:  off
    tags:   enter|leave|trace1|trace2|trace3|trace4|trace6
  }
}

amf {
  mode: disabled
}

aisexec {
  user:  root
  group: root
}
',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/corosync/corosync.conf',
  require => 'Package[corosync]',
}

file { '/etc/corosync/service.d/pacemaker':
  ensure  => 'file',
  content => 'service {
  name: pacemaker
  ver:  1
}
',
  group   => 'root',
  mode    => '0644',
  notify  => 'Service[corosync]',
  owner   => 'root',
  path    => '/etc/corosync/service.d/pacemaker',
  require => 'Package[corosync]',
}

file { '/etc/corosync/service.d':
  ensure  => 'directory',
  group   => 'root',
  mode    => '0755',
  owner   => 'root',
  path    => '/etc/corosync/service.d',
  purge   => 'true',
  recurse => 'true',
  require => 'Package[corosync]',
}

file { '/etc/corosync/uidgid.d/pacemaker':
  before  => 'Service[corosync]',
  content => 'uidgid {
   uid: hacluster
   gid: haclient
}',
  path    => '/etc/corosync/uidgid.d/pacemaker',
}

file { 'limitsconf':
  ensure  => 'present',
  before  => 'Service[corosync]',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/security/limits.conf',
  replace => 'true',
  source  => 'puppet:///modules/openstack/limits.conf',
}

file { 'ocf-fuel-path':
  ensure  => 'directory',
  group   => 'root',
  owner   => 'root',
  path    => '/usr/lib/ocf/resource.d/fuel',
  recurse => 'true',
}

package { 'corosync':
  ensure => 'present',
  before => 'File[ocf-fuel-path]',
  name   => 'corosync',
}

package { 'crmsh':
  ensure => 'present',
  name   => 'crmsh',
}

package { 'pacemaker':
  ensure => 'present',
  before => 'File[ocf-fuel-path]',
  name   => 'pacemaker',
}

package { 'pcs':
  ensure => 'present',
  name   => 'pcs',
}

pcmk_nodes { 'pacemaker':
  add_pacemaker_nodes => 'false',
  name                => 'pacemaker',
  nodes               => {'node-3.test.domain.local' => {'id' => '3', 'ip' => '172.16.1.5'}, 'node-5.test.domain.local' => {'id' => '5', 'ip' => '172.16.1.6'}, 'node-6.test.domain.local' => {'id' => '6', 'ip' => '172.16.1.3'}},
}

service { 'corosync':
  ensure    => 'running',
  before    => 'Pcmk_nodes[pacemaker]',
  enable    => 'true',
  name      => 'corosync',
  require   => 'File[/etc/corosync/corosync.conf]',
  subscribe => 'File[/etc/corosync/service.d]',
}

service { 'pacemaker':
  ensure    => 'running',
  enable    => 'true',
  name      => 'pacemaker',
  subscribe => 'Service[corosync]',
}

stage { 'main':
  name => 'main',
}

