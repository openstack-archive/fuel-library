#ceph::nova_compute will configure the nova_compure parts if present
class ceph::nova_compute (
  $rbd_secret_uuid = $::ceph::rbd_secret_uuid
) {
  if $::fuel_settings['role'] == "compute" {
    exec {'Copy conf':
      command => "scp -r ${::ceph::primary_mon}:/etc/ceph/* /etc/ceph/",
      require => Package['ceph'],
      returns => [0,1],
    }
    file { '/tmp/secret.xml':
      #TODO: use mktemp
      content => template('ceph/secret.erb')
    }
    exec { 'Set value':
      #TODO: clean this command up
      command => 'virsh secret-set-value --secret $( \
        virsh secret-define --file /tmp/secret.xml | \
        egrep -o "[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}") \
        --base64 $(ceph auth get-key client.volumes) && \
        rm /tmp/secret.xml',
      require => [File['/tmp/secret.xml'],
                  Package ['ceph'],
                  Exec['Copy conf']],
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
