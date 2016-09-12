class osnailyfacter::vmware::cinder_vmware {

  notice('MODULAR: vmware/cinder_vmware.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $cinder_hash = hiera_hash('cinder', {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  if roles_include(['cinder-vmware']) {
    $debug   = pick($cinder_hash['debug'], hiera('debug', true))
    $volumes = get_cinder_vmware_data($cinder_hash['instances'], $debug)
    create_resources(vmware::cinder::vmdk, $volumes)
  }
}
