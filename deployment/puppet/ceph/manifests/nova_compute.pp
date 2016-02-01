# configure the nova_compute parts if present
class ceph::nova_compute (
  $rbd_secret_uuid     = $::ceph::rbd_secret_uuid,
  $user                = $::ceph::compute_user,
  $compute_pool        = $::ceph::compute_pool,
  $secret_xml          = '/root/.secret_attrs.xml',
) {

  include ::nova::params

  file { $secret_xml:
    mode    => '0400',
    content => template('ceph/secret.erb')
  }

  # TODO(aschultz): Just use $::nova::params::libvirt_service_name when a
  # version of puppet-nova has been pulled in that uses os_package_type to
  # correctly handle the service names for ubuntu vs debian. Upstream bug
  # LP#1515076
  # NOTE: for debian packages and centos the name is the same ('libvirtd') so
  # we are defaulting to that for backwards compatibility. LP#1469308
  $libvirt_service_name = $::os_package_type ? {
    'ubuntu' => $::nova::params::libvirt_service_name,
    default  => 'libvirtd'
  }

  ensure_resource('service', 'libvirt', {
    ensure => 'running',
    name   => $libvirt_service_name,
  })

  exec {'Set Ceph RBD secret for Nova':
    # TODO: clean this command up
    command => "virsh secret-define --file ${secret_xml} && \
      virsh secret-set-value --secret ${rbd_secret_uuid} \
      --base64 $(ceph auth get-key client.${user})",
    unless => "virsh secret-list | fgrep -qw ${rbd_secret_uuid}",
  }

  nova_config {
    'libvirt/rbd_secret_uuid':          value => $rbd_secret_uuid;
    'libvirt/rbd_user':                 value => $user;
  }

  File[$secret_xml] ->
  Service['libvirt'] -> Exec['Set Ceph RBD secret for Nova']
}
