class osnailyfacter::openstack_haproxy::openstack_haproxy {

  notice('MODULAR: openstack_haproxy/openstack_haproxy.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)
  # This is a placeholder task that is used to tie all the haproxy tasks together.
  # Any haproxy configurations should go in a openstack-haproxy-<SVCNAME> task

}
