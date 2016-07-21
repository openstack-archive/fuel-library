class osnailyfacter::netconfig::hiera_default_route {

  notice('MODULAR: netconfig/hiera_default_route.pp')

  $loaded_network_scheme  = hiera_hash('network_scheme', {})
  $management_vrouter_vip = hiera('management_vrouter_vip')
  $management_role        = 'mgmt/vip'
  $admin_role             = 'admin/pxe'

  # We can safely prepare_network_config for $loaded_network_scheme here
  # because all we need is network roles and their mapping to interfaces.
  # We're not using prepared config anywhere else in this manifest, we're
  # working directly with network_scheme hash instead.
  prepare_network_config($loaded_network_scheme)
  $public_br = get_network_role_property('public/vip', 'interface')
  $admin_br  = get_network_role_property($admin_role, 'interface')
  $mgmt_br   = get_network_role_property($management_role, 'interface')

  if (has_key($loaded_network_scheme['endpoints'], $public_br)
      or !is_ip_address($management_vrouter_vip)) {
    $network_scheme = $loaded_network_scheme
  } else {
    $new_network_scheme = configure_default_route($loaded_network_scheme,
                                              $management_vrouter_vip,
                                              $admin_role,
                                              $management_role)
    $network_scheme = empty($new_network_scheme) ? {
      default => $loaded_network_scheme,
      false   => $new_network_scheme
    }
  }

  # Change default route only if configure_default_route() changed the scheme.
  if $loaded_network_scheme != $network_scheme {
    file {'/etc/hiera/override/configuration/default_route.yaml':
      ensure  => file,
      mode    => '0640',
      content => inline_template('# Created by puppet, please do not edit
network_scheme:
  endpoints:
    <%= @admin_br %>:
      gateway: ""
    <%= @mgmt_br %>:
      gateway: "<%= @management_vrouter_vip %>"
'),
    }
  }
  else {
    file {'/etc/hiera/override/configuration/default_route.yaml':
      ensure  => absent,
    }
  }
}
