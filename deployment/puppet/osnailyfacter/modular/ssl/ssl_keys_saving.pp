notice('MODULAR: ssl_keys_saving.pp')

$public_ssl_hash = hiera('public_ssl')
$certificate_content = $ssl_hash['cert_data']
$base_path = "/etc/pki/tls/certs"
$astute_base_path = "/var/lib/astute/haproxy/"
$service_name = "public_haproxy"

File {
  owner => 'root',
  group => 'root',
  mode  => '0644',
}

file { [ $base_path, $astute_base_path ]:
  ensure => directory,
}->

file { ["$base_path/$service_name.pem", "$astute_base_path/$service_name.pem"]:
  ensure => present,
  content => $certificate_content,
}
