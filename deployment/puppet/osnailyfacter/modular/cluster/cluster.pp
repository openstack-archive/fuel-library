notice('MODULAR: cluster.pp')

$nodes = hiera('nodes')
$role = hiera('role')
$corosync_nodes = corosync_nodes($nodes)

class { '::cluster':
  internal_address  => hiera('internal_address'),
  unicast_addresses => ipsort(values($corosync_nodes)),
}

if $role == 'primary-controller' {
  pcmk_nodes { 'pacemaker' :
    nodes => $corosync_nodes,
    add_pacemaker_nodes => false,
  }
}

Service <| title == 'corosync' |> {
  subscribe => File['/etc/corosync/service.d'],
  require   => File['/etc/corosync/corosync.conf'],
}

Service['corosync'] -> Pcmk_nodes<||>
Pcmk_nodes<||> -> Service<| provider == 'pacemaker' |>
