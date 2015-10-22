notice('MODULAR: ssl_dns_setup.pp')

$public_ssl_hash = hiera('public_ssl')
$ssl_hash = hiera_hash('use_ssl', {})
$public_vip = hiera('public_vip')
$management_vip = hiera('management_vip')
$openstack_service_endpoints = hiera_hash('openstack_service_endpoints', {})

$services = [ 'horizon', 'keystone', 'nova', 'heat', 'glance', 'cinder', 'neutron', 'swift', 'sahara', 'murano', 'ceilometer', 'radosgw']

if !empty($ssl_hash) {
  define hosts (
    $ssl_hash,
    $openstack_service_endpoints,
    ){
    $service = $name
    $public_vip = hiera('public_vip')
    $management_vip = hiera('management_vip')

    $public_hostname = try_get_value($openstack_service_endpoints, "${service}/public/hostname", try_get_value($ssl_hash, "${service}_public_hostname", ""))
    $internal_hostname = try_get_value($openstack_service_endpoints, "${service}/internal/hostname", try_get_value($ssl_hash, "${service}_internal_hostname", ""))
    $admin_hostname = try_get_value($openstack_service_endpoints, "${service}/admin/hostname", try_get_value($ssl_hash, "${service}_admin_hostname", $internal_hostname))

    $public_ip = try_get_value($openstack_service_endpoints, "${service}/public/ip", try_get_value($ssl_hash, "${service}_public_ip", $public_vip))
    $internal_ip = try_get_value($openstack_service_endpoints, "${service}/internal/ip", try_get_value($ssl_hash, "${service}_internal_ip", $management_vip))
    $admin_ip = try_get_value($openstack_service_endpoints, "${service}/admin/ip", try_get_value($ssl_hash, "${service}_admin_ip", $management_vip))

    # We always need to set public hostname resolution
    if !empty($public_hostname) and !defined(Host[$public_hostname]) {
      host { $public_hostname:
        name   => $public_hostname,
        ensure => present,
        ip     => $public_ip,
      }
    }

    if ($public_hostname == $internal_hostname) and ($public_hostname == $admin_hostname) {
      notify{"All ${service} hostnames is equal, just public one inserted to DNS":}
    }
    elsif $public_hostanme == $internal_hostname {
      if !empty($admin_hostname) and !defined(Host[$admin_hostname]) {
        host { $admin_hostname:
          name   => $admin_hostname,
          ensure => present,
          ip     => $admin_ip,
        }
      }
    }
    elsif ($public_hostname == $admin_hostname) or ($internal_hostname == $admin_hostname) {
      if !empty($internal_hostname) and !defined(Host[$internal_hostname]) {
        host { $internal_hostname:
          name   => $internal_hostname,
          ensure => present,
          ip     => $internal_ip,
        }
      }
    }
    else {
      if !empty($admin_hostname) and !defined(Host[$admin_hostname]) {
        host { $admin_hostname:
          name   => $admin_hostname,
          ensure => present,
          ip     => $admin_ip,
        }
      }
      if !empty($internal_hostname) and !defined(Host[$internal_hostname]) {
        host { $internal_hostname:
          name   => $internal_hostname,
          ensure => present,
          ip     => $internal_ip,
        }
      }
    }
  }

  hosts { $services:
    ssl_hash => $ssl_hash,
    openstack_service_endpoints => $openstack_service_endpoints,
  }
} elsif !empty($public_ssl_hash) {
  host { $public_ssl_hash['hostname']:
    ensure => present,
    ip     => $public_vip,
  }
}
