notice('MODULAR: conntrackd.pp')

case $operatingsystem {
  Centos: { $conntrackd_package = "conntrack-tools" }
  Ubuntu: { $conntrackd_package = "conntrackd" }
}


### CONNTRACKD for CentOS 6 doesn't work under namespaces ##

if $operatingsystem == 'Ubuntu' {
  package { $conntrackd_package:
    ensure => installed,
  } ->

  file { '/etc/conntrackd/conntrackd.conf':
    content => template('cluster/conntrackd.conf.erb'),
  } ->

  file { '/usr/lib/ocf/resource.d/fuel/ns_conntrackd':
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ocf/ns_conntrackd',
  } ->

  cs_resource {'p_conntrackd':
    ensure => present,
    primitive_class => 'ocf',
    provided_by     => 'fuel',
    primitive_type  => 'ns_conntrackd',
    metadata => {
      'migration-threshold' => 'INFINITY',
      'failure-timeout'     => '180s'
    },
    complex_type => 'master',
    ms_metadata => {
      'notify'          => 'true',
      'ordered'         => 'false',
      'interleave'      => 'true',
      'clone-node-max'  => '1',
      'master-max'      => '1',
      'master-node-max' => '1',
      'target-role'     => 'Master'
    },
    operations => {
      'monitor'  => {
      'interval' => '30',
      'timeout'  => '60'
    },
    'monitor:Master' => {
      'role'     => 'Master',
      'interval' => '27',
      'timeout'  => '60'
      },
    },
  }

  cs_colocation { 'conntrackd-with-public-vip':
    primitives => [ 'master_p_conntrackd:Master', 'vip__public_vrouter' ],
  }

  File['/etc/conntrackd/conntrackd.conf'] -> Cs_resource['p_conntrackd'] -> Service['p_conntrackd'] -> Cs_colocation['conntrackd-with-public-vip']

  service { 'p_conntrackd':
    ensure   => 'running',
    enable   => true,
    provider => 'pacemaker',
  }
}
