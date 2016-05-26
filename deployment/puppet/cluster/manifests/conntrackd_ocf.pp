class cluster::conntrackd_ocf (
  $vrouter_name,
  $bind_address,
  $mgmt_bridge,
) {
  $service_name = 'conntrackd'

  case $operatingsystem {
    'Centos': { $conntrackd_package = 'conntrack-tools' }
    'Ubuntu': { $conntrackd_package = 'conntrackd' }
  }

  package { $conntrackd_package:
    ensure => 'installed',
  } ->

  file { '/etc/conntrackd/conntrackd.conf':
    content => template('cluster/conntrackd.conf.erb'),
  } ->

  service { $service_name :
    ensure   => 'running',
    enable   => true,
  }

  $primitive_type     = 'ns_conntrackd'
  $primitive_provider = 'fuel'
  $complex_type       = 'master'

  $metadata           = {
    'migration-threshold' => 'INFINITY',
    'failure-timeout'     => '180s'
  }

  $parameters = {
    'bridge' => $mgmt_bridge,
  }

  $complex_metadata   = {
    'notify'          => 'true',
    'ordered'         => 'false',
    'interleave'      => 'true',
    'clone-node-max'  => '1',
    'master-max'      => '1',
    'master-node-max' => '1',
    'target-role'     => 'Master'
  }

  $operations         = {
    'monitor'  => {
      'interval' => '30',
      'timeout'  => '60'
    },
    'monitor:Master' => {
      'role'         => 'Master',
      'interval'     => '27',
      'timeout'      => '60'
    },
  }

  pacemaker::new::wrapper { $service_name :
    primitive_type     => $primitive_type,
    primitive_provider => $primitive_provider,
    metadata           => $metadata,
    parameters         => $parameters,
    complex_type       => $complex_type,
    complex_metadata   => $complex_metadata,
    operations         => $operations,
  }

  pacemaker_colocation { "conntrackd-with-${vrouter_name}-vip":
    first  => "vip__vrouter_${vrouter_name}",
    second => 'conntrackd-master:Master',
  }

  File['/etc/conntrackd/conntrackd.conf'] ->
  Pacemaker_resource[$service_name] ->
  Service[$service_name] ->
  Pacemaker_colocation["conntrackd-with-${vrouter_name}-vip"]

  # Workaround to ensure log is rotated properly
  file { '/etc/logrotate.d/conntrackd':
    content => template('openstack/95-conntrackd.conf.erb'),
  }

  Package[$conntrackd_package] -> File['/etc/logrotate.d/conntrackd']
}
