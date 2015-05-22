notice('MODULAR: ssl_keys_saving.pp')

$public_ssl_hash = hiera_hash('public_ssl')
$pub_certificate_content = $public_ssl_hash['cert_data']['content']
$base_path = "/etc/pki/tls/certs"
$pki_path = [ "/etc/pki", "/etc/pki/tls" ]
$astute_base_path = "/var/lib/astute/haproxy"

File {
  owner => 'root',
  group => 'root',
  mode  => '0644',
}

file { [ $pki_path, $base_path, $astute_base_path ]:
  ensure => directory,
}

file { ["$base_path/public_haproxy.pem", "$astute_base_path/public_haproxy.pem"]:
  ensure => present,
  content => $pub_certificate_content,
}
