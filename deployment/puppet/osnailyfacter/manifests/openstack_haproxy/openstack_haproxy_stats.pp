class osnailyfacter::openstack_haproxy::openstack_haproxy_stats {

  notice('MODULAR: openstack_haproxy/openstack_haproxy_stats.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $external_lb         = hiera('external_lb', false)
  $internal_virtual_ip = unique([hiera('management_vip'), hiera('database_vip'), hiera('service_endpoint')])

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  if !$external_lb {
    class { '::openstack::ha::stats':
      internal_virtual_ip => $internal_virtual_ip,
    }
  }

}
