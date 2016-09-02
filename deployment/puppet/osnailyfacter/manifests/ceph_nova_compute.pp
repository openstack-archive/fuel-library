# configure the nova_compute parts if present
class osnailyfacter::ceph_nova_compute (
  $rbd_secret_uuid     = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  $user                = 'compute',
  $compute_pool        = 'compute',
  $secret_xml          = '/root/.secret_attrs.xml',
  $libvirt_images_type = 'rbd',
) {

  include ::nova::params

  service { $::nova::params::compute_service_name: }

  nova_config {
    'libvirt/images_type':      value => $libvirt_images_type;
    'libvirt/inject_key':       value => false;
    'libvirt/inject_partition': value => '-2';
    'libvirt/images_rbd_pool':  value => $compute_pool;
    'libvirt/rbd_secret_uuid':  value => $rbd_secret_uuid;
    'libvirt/rbd_user':         value => $user;
  }

  file { $secret_xml:
    content => template('osnailyfacter/ceph_secret.erb')
  }

  ensure_resource('service', 'libvirt', {
    ensure => 'running',
    name   => 'libvirt-bin',
  })

  exec {'Set Ceph RBD secret for Nova':
    # TODO: clean this command up
    command => "virsh secret-define --file ${secret_xml} && \
      virsh secret-set-value --secret ${rbd_secret_uuid} \
      --base64 $(ceph auth get-key client.${user})",
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    unless  => "virsh secret-list | fgrep -qw ${rbd_secret_uuid}",
  }

  Nova_config<||> ~>
  Service[$::nova::params::compute_service_name]

  File[$secret_xml] ->
  Service['libvirt'] ->
  Exec['Set Ceph RBD secret for Nova']
}
