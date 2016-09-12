class osnailyfacter::openstack_haproxy::openstack_haproxy {

  notice('MODULAR: openstack_haproxy/openstack_haproxy.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})
  # This is a placeholder task that is used to tie all the haproxy tasks together.
  # Any haproxy configurations should go in a openstack-haproxy-<SVCNAME> task

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

}
