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

  ensure_packages('cirros-testvm')

  $storage_hash = hiera_hash('storage', {})
  $hw_disk_discard = pick($storage_hash['disk_discard'], true)

  if $hw_disk_discard {
    $extra_opts = {
      'properties' => {
        'hw_scsi_model' => 'virtio-scsi',
        'hw_disk_bus'   => 'scsi',
      }
    }
  }

  $test_vm_images = hiera('test_vm_image')
  $glance_images = generate_glance_images(flatten([$test_vm_images]), pick($extra_opts, {}))
  $defaults = {
    'ensure' => 'present',
  }

  include ::osnailyfacter::wait_for_glance_backends

  create_resources(glance_image, $glance_images, $defaults)

  Class['osnailyfacter::wait_for_glance_backends'] -> Package['cirros-testvm'] -> Glance_image<||>
}
