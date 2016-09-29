class openstack_tasks::ceilometer::radosgw_user {

  notice('MODULAR: ceilometer/radosgw_user.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  $default_ceilometer_hash = {
    'enabled' => false,
  }

  $ceilometer_hash = hiera_hash('ceilometer', $default_ceilometer_hash)

  if $ceilometer_hash['enabled'] {
    include ::ceilometer::params

    ceilometer_radosgw_user { 'ceilometer':
      caps => {'buckets' => 'read', 'usage' => 'read'},
    } ~>
    service { $::ceilometer::params::agent_central_service_name:
      ensure   => 'running',
      enable   => true,
      provider => 'pacemaker',
    }
  }

}
