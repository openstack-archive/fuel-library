class nailgun::nginx-ssl {

  openssl::certificate::x509 { 'nginx':
    ensure          => present,
    country         => 'US',
    organization    => 'Mirantis',
    commonname      => 'fuel.master.local',
    state           => 'California',
    unit            => 'Fuel Deployment Team',
    email           => "root@fuel.master.local",
    days            => 3650,
    base_dir        => '/etc/pki/tls/',
    owner           => 'root',
    group           => 'root',
    force           => false,
    cnf_tpl         => 'openssl/cert.cnf.erb',
  }
}
