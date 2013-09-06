class ceph::nova_compute (
  $rbd_secret_uuid = $::ceph::cinder::rbd_secret_uuid
) {
  if $::role == "compute" {
    exec {'Copy conf':
      command => "scp -r ${mon_nodes[-1]}:/etc/ceph/* /etc/ceph/",
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
    #TODO: RHEL conversion
    service {'openstack-nova-compute':
      ensure     => "running",
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      subscribe  => Exec['Set value']
    } -> exec {'rm secret.xml':
      command => "rm /tmp/secret.xml",
    }
  }
}
