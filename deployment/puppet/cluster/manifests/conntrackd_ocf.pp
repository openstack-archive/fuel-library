class cluster::conntrackd_ocf (
  $vrouter_name,
  $bind_address,
  $mgmt_bridge,
) {
  $service_name = 'p_conntrackd'
  $conntrackd_package = 'conntrackd'

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

  tweaks::ubuntu_service_override { 'conntrackd': }

  $primitive_class    = 'ocf'
  $primitive_provider = 'fuel'
  $primitive_type     = 'ns_conntrackd'
  $metadata           = {
    'migration-threshold' => 'INFINITY',
    'failure-timeout'     => '180s'
  }
  $parameters = {
    'bridge' => $mgmt_bridge,
  }
  $complex_type       = 'master'
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

  pacemaker::service { $service_name :
    prefix             => false,
    primitive_class    => $primitive_class,
    primitive_provider => $primitive_provider,
    primitive_type     => $primitive_type,
    metadata           => $metadata,
    parameters         => $parameters,
    complex_type       => $complex_type,
    complex_metadata   => $complex_metadata,
    operations         => $operations,
  }

  pcmk_colocation { "conntrackd-with-${vrouter_name}-vip":
    first  => "vip__vrouter_${vrouter_name}",
    second => 'master_p_conntrackd:Master',
  }

  File['/etc/conntrackd/conntrackd.conf'] ->
  Pcmk_resource[$service_name] ->
  Service[$service_name] ->
  Pcmk_colocation["conntrackd-with-${vrouter_name}-vip"]

  # Workaround to ensure log is rotated properly
  file { '/etc/logrotate.d/conntrackd':
    content => template('openstack/95-conntrackd.conf.erb'),
  }

  Package[$conntrackd_package] -> File['/etc/logrotate.d/conntrackd']
}
