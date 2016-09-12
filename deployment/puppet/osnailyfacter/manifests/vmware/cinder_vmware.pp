class osnailyfacter::vmware::cinder_vmware {

  notice('MODULAR: vmware/cinder_vmware.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  $cinder_hash = hiera_hash('cinder', {})

  if roles_include(['cinder-vmware']) {
    $debug   = pick($cinder_hash['debug'], hiera('debug', true))
    $volumes = get_cinder_vmware_data($cinder_hash['instances'], $debug)
    create_resources(vmware::cinder::vmdk, $volumes)
  }
}
