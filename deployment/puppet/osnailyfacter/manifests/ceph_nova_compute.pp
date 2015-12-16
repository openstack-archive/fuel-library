# configure the nova_compute parts if present
class osnailyfacter::ceph_nova_compute (
  $rbd_secret_uuid     = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  $user                = 'compute',
  $compute_pool        = 'compute',
  $secret_xml          = '/root/.secret_attrs.xml',
) {

  include ::nova::params

  file { $secret_xml:
    content => template('osnailyfacter/ceph_secret.erb')
  }

  ensure_resource('service', 'libvirt', {
    ensure => 'running',
    name   => $::nova::params::libvirt_service_name,
  })

  exec {'Set Ceph RBD secret for Nova':
    # TODO: clean this command up
    command => "virsh secret-define --file ${secret_xml} && \
      virsh secret-set-value --secret ${rbd_secret_uuid} \
      --base64 $(ceph auth get-key client.${user})",
    unless => "virsh secret-list | fgrep -qw ${rbd_secret_uuid}",
  }

  nova_config {
    'libvirt/rbd_secret_uuid': value => $rbd_secret_uuid;
    'libvirt/rbd_user':        value => $user;
  }

  File[$secret_xml] ->
  Service['libvirt'] ->
  Exec['Set Ceph RBD secret for Nova']
}

