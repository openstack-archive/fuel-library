# configure the nova_compute parts if present
class ceph::nova_compute (
  $rbd_secret_uuid     = $::ceph::rbd_secret_uuid,
  $user                = $::ceph::compute_user,
  $compute_pool        = $::ceph::compute_pool,
) {

  include ::nova::params

  file {'/root/secret.xml':
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

  if !defined($libvirt_service_name ) {
    service { 'libvirt':
      name   => $libvirt_service_name,
      ensure => 'running',
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
