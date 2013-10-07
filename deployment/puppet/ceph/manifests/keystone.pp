#ceph::keystone will configure keystone with ceph parts
class ceph::keystone (
  $pub_ip    = $::ceph::rgw_pub_ip,
  $adm_ip    = $::ceph::rgw_adm_ip,
  $int_ip    = $::ceph::rgw_int_ip,
  $rgw_port  = $::ceph::rgw_port,
  $use_ssl   = $::ceph::use_ssl,
  $directory = $::ceph::rgw_nss_db_path,
) {
  if ($use_ssl) {
    exec {'creating OpenSSL certificates':
      command => "openssl x509 -in /etc/keystone/ssl/certs/ca.pem -pubkey | \
      certutil -d ${directory} -A -n ca -t 'TCu,Cu,Tuw' && openssl x509  \
      -in /etc/keystone/ssl/certs/signing_cert.pem -pubkey | \
      certutil -A -d ${directory} -n signing_cert -t 'P,P,P'",
      require => [File[$directory], Package[$::ceph::params::package_libnss]]
    } ->
    exec {'copy OpenSSL certificates':
      command => "scp -r ${directory}/* ${::ceph::primary_mon}:${directory} && \
                  ssh ${::ceph::primary_mon} '/etc/init.d/radosgw restart'",
    }
  }

  keystone_service {'swift':
    ensure      => present,
    type        => 'object-store',
    description => 'Openstack Object-Store Service',
  }

  keystone_endpoint {'swift':
    ensure       => present,
    region       => 'RegionOne',
    public_url   => "http://${pub_ip}:${rgw_port}/swift/v1",
    admin_url    => "http://${adm_ip}:${rgw_port}/swift/v1",
    internal_url => "http://${int_ip}:${rgw_port}/swift/v1",
  }

  if ! defined(Class['keystone']) {
    service { 'keystone':
      ensure => 'running',
      enable => true,
    }
  }
}
