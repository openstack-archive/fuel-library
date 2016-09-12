class osnailyfacter::astute::purge_service_entries {

  notice('MODULAR: astute/purge_service_entries.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

  ####################################################################
  # Used as singular by post-deployment action to purge nova services
  # from deleted hosts
  #
  $deleted_hosts = hiera('deleted_nodes',[])

  unless empty($deleted_hosts) {
    ensure_resource('nova_service', $deleted_hosts, {'ensure' => 'absent'})
  }

}
