class openstack_tasks::murano::upload_murano_package {

  notice('MODULAR: murano/upload_murano_package.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  murano::application { 'io.murano' :
    exists_action => 'u'
  }
}
