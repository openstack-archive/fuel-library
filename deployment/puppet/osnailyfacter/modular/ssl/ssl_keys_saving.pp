notice('MODULAR: ssl_keys_saving.pp')

$ssl_hash = hiera('ssl')
if ($ssl_hash['services'] or $ssl_hash['horizon']) and $ssl_hash['cert_source'] == 'user_uploaded' {
  $certificate_content = $ssl_hash['cert_data']
  $base_path = "/var/lib/astute/"
  $service_name = "haproxy"

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  file { [ $base_path, "$base_path/$service_name" ]:
    ensure => directory,
  }->

  file { "$base_path/$service_name/$service_name.pem":
    ensure => present,
    content => $certificate_content,
  }
}
