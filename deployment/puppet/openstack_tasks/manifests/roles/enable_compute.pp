class openstack_tasks::roles::enable_compute {

  notice('MODULAR: roles/enable_compute.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})
  include ::nova::params

  $compute_service_name = $::nova::params::compute_service_name
  $use_ovs              = hiera('use_ovs', true)
  $roles                = hiera('roles')
                                                                                               
  override_resources {'override-resources':
    configuration => $override_configuration,                                                  
    options       => $override_configuration_options,                                          
  }

  if !('compute-vmware' in $roles) and $use_ovs {
    $neutron_integration_bridge = 'br-int'
    $bridge_exists_check        = "ovs-vsctl br-exists ${neutron_integration_bridge}"

    # We need to restart nova-compute service in orderto apply new settings
    # nova-compute must not be restarted until integration bridge is created by
    # Neutron L2 agent.
    # The reason is described here https://bugs.launchpad.net/fuel/+bug/1477475
    exec { 'wait-for-int-br':
      command   => $bridge_exists_check,
      path      => ['/usr/bin', '/usr/sbin'],
      unless    => $bridge_exists_check,
      try_sleep => 6,
      tries     => 10,
    }

    Exec['wait-for-int-br'] -> Service['nova-compute']
  }

  service { 'nova-compute':
    ensure     => running,
    name       => $compute_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

}
