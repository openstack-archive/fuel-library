notice('MODULAR: cluster.pp')

if !(hiera('role') in hiera('corosync_roles')) {
    fail('The node role is not in corosync roles')
}

prepare_network_config(hiera_hash('network_scheme'))

$corosync_nodes = corosync_nodes(
    get_nodes_hash_by_roles(
        hiera_hash('network_metadata'),
        hiera('corosync_roles')
    ),
    'mgmt/corosync'
)

class { 'cluster':
  internal_address => get_network_role_property('mgmt/corosync', 'ipaddr'),
  corosync_nodes   => $corosync_nodes,
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

# Sometimes pacemaker can not connect to corosync
# via IPC

file {'/etc/corosync/uidgid.d/hacluster':
  content =>"
uidgid {
   uid: hacluster
   gid: haclient
}
"
}

File['/etc/corosync/corosync.conf'] -> File['/etc/corosync/uidgid.d/hacluster'] -> Service <| title == 'corosync' |>
