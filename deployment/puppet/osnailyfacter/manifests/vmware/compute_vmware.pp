class osnailyfacter::vmware::compute_vmware {

  notice('MODULAR: vmware/compute_vmware.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $debug         = hiera('debug', true)

  $vcenter_hash  = hiera_hash('vcenter', {})
  $computes      = $vcenter_hash['computes']
  $computes_hash = parse_vcenter_settings($computes)

  $defaults = {
    current_node   => hiera('node_name'),
    vlan_interface => $vcenter_hash['esxi_vlan_interface']
  }

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  create_resources(vmware::compute_vmware, $computes_hash, $defaults)

  $ceilometer_hash    = hiera_hash('ceilometer', {})
  $ceilometer_enabled = $ceilometer_hash['enabled']

  if $ceilometer_enabled and $computes {
    $compute  = $computes[0]

    $password = $ceilometer_hash['user_password']
    $tenant   = pick($ceilometer_hash['tenant'], 'services')

    $service_endpoint = hiera('service_endpoint')
    $management_vip   = hiera('management_vip')
    $ssl_hash         = hiera_hash('use_ssl', {})
    $auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
    $auth_host        = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])

    $auth_port    = '5000'
    $identity_uri = "${auth_protocol}://${auth_host}:${auth_port}"

    class { '::vmware::ceilometer::compute_vmware':
      debug                  => $debug,
      availability_zone_name => $compute['availability_zone_name'],
      vc_cluster             => $compute['vc_cluster'],
      vc_host                => $compute['vc_host'],
      vc_user                => $compute['vc_user'],
      vc_password            => $compute['vc_password'],
      vc_insecure            => $compute['vc_insecure'],
      vc_ca_file             => $compute['vc_ca_file'],
      service_name           => $compute['service_name'],
      identity_uri           => $identity_uri,
      auth_user              => 'ceilometer',
      auth_password          => $password,
      tenant                 => $tenant,
    }
  }

}
