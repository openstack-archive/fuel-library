define ceph::keystone (
  $pub_ip,
  $adm_ip,
  $int_ip,
  $directory = '/etc/ceph/nss',
) {
  if str2bool($::keystone_conf) {
    package { "libnss3-tools" :
      ensure => 'latest'
    }
    file { "${directory}":
      ensure  => "directory",
      require => Package['ceph'],
    }
    exec {"creating OpenSSL certificates":
      command => "openssl x509 -in /etc/keystone/ssl/certs/ca.pem -pubkey  \
      | certutil -d ${directory} -A -n ca -t 'TCu,Cu,Tuw' && openssl x509  \
      -in /etc/keystone/ssl/certs/signing_cert.pem -pubkey | certutil -A -d \
      ${directory} -n signing_cert -t 'P,P,P'",
      require => [File["${directory}"], Package["libnss3-tools"]]
    } ->
    exec {"copy OpenSSL certificates":
      command => "scp -r /etc/ceph/nss/* ${rados_GW}:/etc/ceph/nss/ && ssh ${rados_GW} '/etc/init.d/radosgw restart'",
    }
    keystone_service { "swift":
      ensure      => present,
      type        => 'object-store',
      description => 'Openstack Object-Store Service',
      notify      => Service['keystone'],
    }
    keystone_endpoint { "RegionOne/swift":
      ensure       => present,
      public_url   => "http://${pub_ip}/swift/v1",
      admin_url    => "http://${adm_ip}/swift/v1",
      internal_url => "http://${int_ip}/swift/v1",
      notify       => Service['keystone'],
    }
    service { "keystone":
      enable => true,
      ensure => "running",
    }
  }
}
