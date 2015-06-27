notice('MODULAR: ssl_keys_saving.pp')

$public_ssl_hash = hiera('public_ssl')
$pub_certificate_content = $public_ssl_hash['cert_data']
$internal_ssl_hash = hiera('internal_ssl')
$int_certificate_content = $internal_ssl_hash['cert_data']
$admin_ssl_hash = hiera('admin_ssl')
$adm_certificate_content = $admin_ssl_hash['cert_data']
$base_path = "/etc/pki/tls/certs"
$astute_base_path = "/var/lib/astute/haproxy/"

File {
  owner => 'root',
  group => 'root',
  mode  => '0644',
}

file { [ $base_path, $astute_base_path ]:
  ensure => directory,
}->

file { ["$base_path/public_haproxy.pem", "$astute_base_path/public_haproxy.pem"]:
  ensure => present,
  content => $pub_certificate_content,
}

file { ["$base_path/internal_haproxy.pem", "$astute_base_path/internal_haproxy.pem"]:
  ensure => present,
  content => $int_certificate_content,
}

file { ["$base_path/admin_haproxy.pem", "$astute_base_path/admin_haproxy.pem"]:
  ensure => present,
  content => $adm_certificate_content,
}
