notice('MODULAR: ssl_keys_saving.pp')

$public_ssl_hash = hiera_hash('public_ssl')
$ssl_hash = hiera_hash('use_ssl', {})
$pub_certificate_content = try_get_value($public_ssl_hash, 'cert_data/content', "")
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

#TODO(sbog): convert it to '.each' syntax when moving to Puppet 4
define cert_file (
  $ssl_hash,
  $base_path,
  $astute_base_path,
  ){
  $service = $name

  $public_service = try_get_value($ssl_hash, "${service}_public", false)
  $public_usercert = try_get_value($ssl_hash, "${service}_public_usercert", false)
  $public_certdata = try_get_value($ssl_hash, "${service}_public_certdata/content", "")
  $internal_service = try_get_value($ssl_hash, "${service}_internal", false)
  $internal_usercert = try_get_value($ssl_hash, "${service}_internal_usercert", false)
  $internal_certdata = try_get_value($ssl_hash, "${service}_internal_certdata/content", "")
  $admin_service = try_get_value($ssl_hash, "${service}_admin", false)
  $admin_usercert = try_get_value($ssl_hash, "${service}_admin_usercert", false)
  $admin_certdata = try_get_value($ssl_hash, "${service}_admin_certdata/content", "")

  if $ssl_hash["${service}"] {
    if $public_service and $public_usercert and !empty($public_certdata) {
      file { ["${base_path}/public_${service}.pem", "${astute_base_path}/public_${service}.pem"]:
        ensure  => present,
        content => $public_certdata,
      }
    }
    if $internal_service and $internal_usercert and !empty($internal_certdata) {
      file { ["${base_path}/internal_${service}.pem", "${astute_base_path}/internal_${service}.pem"]:
        ensure  => present,
        content => $internal_certdata,
      }
    }
    if $admin_service and $admin_usercert and !empty($admin_certdata) {
      file { ["${base_path}/admin_${service}.pem", "${astute_base_path}/admin_${service}.pem"]:
        ensure  => present,
        content => $admin_certdata,
      }
    }
  }
}

if !empty($ssl_hash) {
  $services = [ 'horizon', 'keystone', 'nova', 'heat', 'glance', 'cinder', 'neutron', 'swift', 'sahara', 'ceilometer', 'radosgw']

  cert_file { $services:
    ssl_hash => $ssl_hash,
    base_path => $base_path,
    astute_base_path => $astute_base_path,
  }
} elsif !empty($public_ssl_hash) {
  file { ["$base_path/public_haproxy.pem", "$astute_base_path/public_haproxy.pem"]:
    ensure => present,
    content => $pub_certificate_content,
  }
}
