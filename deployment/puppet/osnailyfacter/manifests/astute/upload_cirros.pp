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

  $test_vm_images = hiera_hash('test_vm_image')
  $glance_images = generate_glance_images(any2array($test_vm_images))

  include ::osnailyfacter::wait_for_glance_backends

  create_resource(glance_image, $glance_images)

  Class['osnailyfacter::wait_for_glance_backends'] -> Glance_image<||>
}
