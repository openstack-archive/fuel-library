# configure the nova_compute parts if present
class ceph::nova_compute (
  $rbd_secret_uuid     = $::ceph::rbd_secret_uuid,
  $user                = $::ceph::compute_user,
  $compute_pool        = $::ceph::compute_pool,
) {

  file {'/root/secret.xml':
    content => template('ceph/secret.erb')
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

  case $::osfamily {
    'RedHat': {
      file {$::ceph::params::compute_opts_file:
        ensure => present,
      } ->
      file_line {'nova-compute env':
        path => $::ceph::params::compute_opts_file,
        line => "export CEPH_ARGS='--id ${compute_pool}'",
      }
    }

    'Debian': {
      file {$::ceph::params::compute_opts_file:
        ensure => present,
      } ->
      file_line {'nova-compute env':
        path => $::ceph::params::compute_opts_file,
        line => "env CEPH_ARGS='--id ${compute_pool}'",
      }
    }

    default: {}
  }

  File['/root/secret.xml'] ->
  Exec['Set Ceph RBD secret for Nova']
}
