class openstack_tasks::murano::cfapi {

  notice('MODULAR: murano/cfapi.pp')

  prepare_network_config(hiera_hash('network_scheme', {}))

  $access_hash                = hiera_hash('access', {})
  $murano_cfapi_hash          = hiera_hash('murano-cfapi', {})
  $public_ip                  = hiera('public_vip')
  $management_ip              = hiera('management_vip')
  $public_ssl_hash            = hiera_hash('public_ssl', {})
  $ssl_hash                   = hiera_hash('use_ssl', {})

  $public_auth_protocol       = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'protocol', 'http')
  $public_auth_address        = get_ssl_property($ssl_hash, $public_ssl_hash, 'keystone', 'public', 'hostname', [$public_ip])

  $internal_api_protocol      = 'http'
  $cfapi_bind_host            = get_network_role_property('murano/cfapi', 'ipaddr')

  $service_endpoint           = hiera('service_endpoint')

  #################################################################

  if $murano_cfapi_hash['enabled'] {

    $firewall_rule  = '203 murano-cfapi'

    $cfapi_bind_port = '8083'

    firewall { $firewall_rule :
      dport  => $cfapi_bind_port,
      proto  => 'tcp',
      action => 'accept',
    }

    ####### Disable upstart startup on install #######
    tweaks::ubuntu_service_override { ['murano-cfapi']:
      package_name => 'murano-cfapi',
    }

    class { '::murano::cfapi' :
      tenant    => $access_hash['tenant'],
      bind_host => $cfapi_bind_host,
      bind_port => $cfapi_bind_port,
      auth_url  => "${public_auth_protocol}://${public_auth_address}:5000/v3",
    }
    Firewall[$firewall_rule] -> Class['::murano::cfapi']
  }

}
