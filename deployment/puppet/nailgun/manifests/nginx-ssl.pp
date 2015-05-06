class nailgun::nginx-ssl {

  openssl::certificate::x509 { 'nginx':
    ensure          => present,
    country         => 'RU',
    organization    => 'Mirantis',
    commonname      => $::fqdn,
    state           => 'Moscow',
    unit            => 'Fuel Deployment Team',
    email           => "root@${::fqdn}",
    days            => 3650,
    base_dir        => '/etc/pki/tls/',
    owner           => 'root',
    group           => 'root',
    force           => false,
    cnf_tpl         => 'openssl/cert.cnf.erb',
  }
}