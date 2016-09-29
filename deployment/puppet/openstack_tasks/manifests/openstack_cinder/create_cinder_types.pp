class openstack_tasks::openstack_cinder::create_cinder_types {

  notice('MODULAR: openstack_cinder/create_cinder_types.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $storage_hash    = hiera_hash('storage', {})
  $backends        = $storage_hash['volume_backend_names']

  $available_backends        = delete_values($backends, false)
  $available_backend_names   = keys($available_backends)

  $unavailable_backends      = delete($backends, $available_backend_names)
  $unavailable_backend_names = keys($unavailable_backends)
                                                                                               
  override_resources {'override-resources':
    configuration => $override_configuration,                                                  
    options       => $override_configuration_options,                                          
  }

  ::osnailyfacter::openstack::manage_cinder_types { $available_backend_names:
    ensure               => 'present',
    volume_backend_names => $available_backends,
  }
  ::osnailyfacter::openstack::manage_cinder_types { $unavailable_backend_names:
    ensure => 'absent',
  }

}
