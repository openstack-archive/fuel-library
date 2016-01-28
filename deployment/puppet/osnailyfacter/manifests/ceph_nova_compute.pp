# configure the nova_compute parts if present
class osnailyfacter::ceph_nova_compute (
  $rbd_secret_uuid     = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  $user                = 'compute',
  $compute_pool        = 'compute',
) {

  include ::nova::params

  file {'/root/secret.xml':
    content => template('osnailyfacter/ceph_secret.erb')
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

  if !defined(Service['libvirt']) {
    service { 'libvirt':
      name   => 'libvirtd',
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
    'libvirt/rbd_secret_uuid': value => $rbd_secret_uuid;
    'libvirt/rbd_user':        value => $user;
  }

  File['/root/secret.xml'] ->
  Service['libvirt'] -> Exec['Set Ceph RBD secret for Nova']
}

