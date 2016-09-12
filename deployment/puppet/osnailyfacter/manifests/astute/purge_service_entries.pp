class osnailyfacter::astute::purge_service_entries {

  notice('MODULAR: astute/purge_service_entries.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  ####################################################################
  # Used as singular by post-deployment action to purge nova services
  # from deleted hosts
  #
  $deleted_hosts = hiera('deleted_nodes',[])

  unless empty($deleted_hosts) {
    ensure_resource('nova_service', $deleted_hosts, {'ensure' => 'absent'})
  }

}
