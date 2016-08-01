# == Class: osnailyfacter::astute::upload_cirros
#
# Task to upload a basic cirros image to the evironment.
#
# == Paramters:
#
# N/A
#
class osnailyfacter::astute::upload_cirros {

  notice('MODULAR: astute/upload_cirros.pp')

  package { 'cirros-testvm' :
      ensure => 'installed',
      name   => 'cirros-testvm',
  }

  $test_vm_images = hiera('test_vm_image')
  $glance_images = generate_glance_images(flatten([$test_vm_images]))
  $defaults = {
    'ensure' => 'present',
  }

  include ::osnailyfacter::wait_for_glance_backends

  create_resources(glance_image, $glance_images, $defaults)

  Class['osnailyfacter::wait_for_glance_backends'] -> Package['cirros-testvm'] -> Glance_image<||>
}
