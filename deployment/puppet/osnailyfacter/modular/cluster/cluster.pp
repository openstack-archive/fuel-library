notice('MODULAR: cluster.pp')

if ! roles_include(hiera('corosync_roles')) {
  fail('The node role is not in corosync roles')
}

prepare_network_config(hiera_hash('network_scheme', {}))

$corosync_nodes = corosync_nodes(
    get_nodes_hash_by_roles(
        hiera_hash('network_metadata'),
        hiera('corosync_roles')
    ),
    'mgmt/corosync'
)
$cluster_recheck_interval = hiera('cluster_recheck_interval', '190s')

class { 'cluster':
  internal_address         => get_network_role_property('mgmt/corosync', 'ipaddr'),
  corosync_nodes           => $corosync_nodes,
  cluster_recheck_interval => $cluster_recheck_interval,
}

pcmk_nodes { 'pacemaker' :
  nodes => $corosync_nodes,
  add_pacemaker_nodes => false,
}

Service <| title == 'corosync' |> {
  subscribe => File['/etc/corosync/service.d'],
  require   => File['/etc/corosync/corosync.conf'],
}

Service['corosync'] -> Pcmk_nodes<||>
Pcmk_nodes<||> -> Service<| provider == 'pacemaker' |>

# Sometimes during first start pacemaker can not connect to corosync
# via IPC due to pacemaker and corosync processes are run under different users
if($::operatingsystem == 'Ubuntu') {
  $pacemaker_run_uid = 'hacluster'
  $pacemaker_run_gid = 'haclient'

  file {'/etc/corosync/uidgid.d/pacemaker':
    content =>"uidgid {
   uid: ${pacemaker_run_uid}
   gid: ${pacemaker_run_gid}
}"
  }

  File['/etc/corosync/corosync.conf'] -> File['/etc/corosync/uidgid.d/pacemaker'] -> Service <| title == 'corosync' |>
}
