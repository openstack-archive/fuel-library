# Creates fencing primitives and resource monitoring attributes.
# fuel_settings['nodes']['fence_primitives'] should be passed as fence_primitives hash for every node in the cluster.
class cluster::fencing_primitives (
  $fence_primitives,
  $fence_topology,
) {
# FIXME use filter_hash($::fuel_settings['nodes'], 'pacemaker_hostname') after https://bugs.launchpad.net/fuel/+bug/1267461 had fixed
#  $fqdns = filter_hash($::fuel_settings['nodes'], 'fqdn')
  case $::osfamily {
    'RedHat': {
       $fqdns = filter_hash($::fuel_settings['nodes'], 'fqdn')
    }
    'Debian': {
       $fqdns = filter_hash($::fuel_settings['nodes'], 'name')
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
  $res_name = 'fencing_topology'

#  Create fencing primitives
  anchor {'Fencing primitives start':}
  anchor {'Fencing primitives end':}
  $cib_name = "stonith__${::hostname}"
  cs_shadow { $cib_name: cib => $cib_name }
  cs_commit { $cib_name: cib => $cib_name }

  create_resources('cluster::fencing', $fence_primitives)

  ::corosync::cleanup { $res_name: }
  cs_fencetopo { $res_name:
    ensure         => present,
    cib            => $cib_name,
    fence_topology => $fence_topology,
    nodes          => $fqdns,
  }
  cs_property {'stonith-enabled': value  => 'true' }
  package {'fence-agents':}

  cs_resource { "SysInfo__${::hostname}":
    ensure          => present,
    cib             => "stonith__${::hostname}",
    primitive_class => 'ocf',
    provided_by     => 'pacemaker',
    primitive_type  => 'SysInfo',
    parameters => {
      'delay'       => '5s',
    },
    operations => {
      'monitor' => {
        'interval' => '60s',
        'timeout'  => '120s'
      },
      'start' => {
        'interval' => '0', 'timeout' => '120s', 'on-fail' => 'restart'
      },
      'stop' => {
         'interval' => '0', 'timeout' => '1800s', 'on-fail' => 'restart'
      },
    },
  }

  cs_location {"location__SysInfo__${::hostname}":
    cib        => "stonith__${::hostname}",
    node_name  => $::pacemaker_hostname,
    node_score => 'INFINITY',
    primitive  => "SysInfo__${::hostname}"
  }
  ::corosync::cleanup { "SysInfo__${::hostname}": }

  Class['corosync'] -> Cluster::Fencing <||>
  if defined(Corosync::Service['pacemaker']) {
    Corosync::Service['pacemaker'] -> Cluster::Fencing <||>
  }
  Anchor['Fencing primitives start'] ->
  Package['fence-agents'] ->
  Cs_shadow[$cib_name] ->
  Cluster::Fencing<||> ->
  Cs_fencetopo[$res_name] ->
  Cs_resource["SysInfo__${::hostname}"] ->
  Cs_location["location__SysInfo__${::hostname}"] ->
  Cs_commit[$cib_name] ->
  Cs_property['stonith-enabled'] ->
  Anchor['Fencing primitives end']
}
