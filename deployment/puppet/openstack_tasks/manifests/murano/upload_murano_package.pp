class openstack_tasks::murano::upload_murano_package {

  notice('MODULAR: murano/upload_murano_package.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  murano::application { 'io.murano' :
    exists_action => 'u'
  }
}
