#ceph::nova_compute will configure the nova_compure parts if present
class ceph::nova_compute (
  $rbd_secret_uuid = $::ceph::rbd_secret_uuid
) {
  if $::fuel_settings['role'] == "compute" {

    file { '/root/secret.xml':
      #TODO: use mktemp
      content => template('ceph/secret.erb')
    }
    exec { 'Set value':
      #TODO: clean this command up
      command => 'virsh secret-set-value --secret $( \
        virsh secret-define --file /root/secret.xml | \
        egrep -o "[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}") \
        --base64 $(ceph auth get-key client.volumes) && \
        rm /root/secret.xml',
      require => [File['/root/secret.xml'],
                  Package ['ceph'],
                  Exec['ceph-deploy init config']],
      returns => [0,1],
    }
    if ! defined('nova::compute') {
      service {"${::ceph::params::service_nova_compute}":
        ensure     => "running",
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        subscribe  => Exec['Set value']
      }
    }
  }
}
