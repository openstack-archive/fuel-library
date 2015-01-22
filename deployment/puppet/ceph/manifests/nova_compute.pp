# configure the nova_compute parts if present
class ceph::nova_compute (
  $rbd_secret_uuid     = $::ceph::rbd_secret_uuid,
  $user                = $::ceph::compute_user,
  $compute_pool        = $::ceph::compute_pool,
) {

  file {'/root/secret.xml':
    content => template('ceph/secret.erb')
  }

  ceph_conf {
    'client/rbd cache':                          value => 'true';
    'client/rbd cache writethrough until flush': value => 'true';
    'client/admin socket':                       value => '/var/run/ceph/rbd-client-$pid.asok';
  }

  exec {'Set Ceph RBD secret for Nova':
    # TODO: clean this command up
    command => "virsh secret-set-value --secret $( \
      virsh secret-define --file /root/secret.xml | \
      egrep -o '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}') \
      --base64 $(ceph auth get-key client.${user}) && \
      rm /root/secret.xml",
  }

  nova_config {
    'DEFAULT/rbd_secret_uuid':          value => $rbd_secret_uuid;
    'DEFAULT/rbd_user':                 value => $user;
  }

  File['/root/secret.xml'] ->
  Exec['Set Ceph RBD secret for Nova']
}
