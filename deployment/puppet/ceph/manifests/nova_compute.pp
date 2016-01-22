# configure the nova_compute parts if present
class ceph::nova_compute (
  $rbd_secret_uuid     = $::ceph::rbd_secret_uuid,
  $user                = $::ceph::compute_user,
  $compute_pool        = $::ceph::compute_pool,
) {

  file {'/root/secret.xml':
    content => template('ceph/secret.erb')
  }

  if !defined(Service['libvirt'] ) {
    service { 'libvirt':
      ensure => 'running',
      name   => $::ceph::params::libvirt_service_name,
    }
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
    'libvirt/rbd_secret_uuid':          value => $rbd_secret_uuid;
    'libvirt/rbd_user':                 value => $user;
  }

  File['/root/secret.xml'] ->
  Service['libvirt'] -> Exec['Set Ceph RBD secret for Nova']
}
