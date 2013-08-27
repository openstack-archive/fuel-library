class ceph::nova_compute (
  $rbd_secret_uuid = $::ceph::cinder::rbd_secret_uuid
) {
  if str2bool($::nova_compute) {
    exec {'Copy conf':
      command => "scp -r ${ceph_nodes[-1]}:/etc/ceph/* /etc/ceph/",
      require => Package['ceph'],
      returns => [0,1],
    }
    file { '/tmp/secret.xml':
      #TODO: use mktemp
      content => template('ceph/secret.erb')
    }
    exec { 'Set value':
      command => 'virsh secret-set-value --secret $(virsh secret-define --file /tmp/secret.xml | egrep -o "[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}") --base64 $(ceph auth get-key client.volumes) && rm /tmp/secret.xml',
      require => [File['/tmp/secret.xml'], Package ['ceph'], Exec['Copy conf']],
      returns => [0,1],
    }
    service {'nova-compute':
      ensure     => "running",
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      subscribe  => Exec['Set value']
    } -> file {'/tmp/secret.xml':
      ensure => absent,
    }
  }
}
