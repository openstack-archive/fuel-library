notice('MODULAR: nginx_services.pp')

$fuel_settings = parseyaml($astute_settings_yaml)

if $fuel_settings['SSL'] {
  $force_https = $fuel_settings['SSL']['force_https']
} else {
  $force_https = undef
}

case $::osfamily {
  'RedHat': {
    if ($::operatingsystemrelease =~ /^7.*/) {
      $service_enabled = true
    } else {
      $service_enabled = false
    }
  }
  default: { $service_enabled = false }
}

node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  class { 'fuel::nginx::services':
    ostf_host       => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    keystone_host   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    nailgun_host    => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    service_enabled => $service_enabled,
    ssl_enabled     => true,
    force_https     => $force_https,
  }
}
