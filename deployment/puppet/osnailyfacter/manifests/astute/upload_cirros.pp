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

  $test_vm_image = hiera_hash('test_vm_image')

  include ::osnailyfacter::wait_for_glance_backends

  #TODO(aschultz): extend glance_image to support extra options
  glance_image { $test_vm_image['img_name']:
    ensure           => present,
    container_format => $test_vm_image['container_format'],
    disk_format      => $test_vm_image['disk_format'],
    is_public        => $test_vm_image['public'],
    min_ram          => $test_vm_image['min_ram'],
    source           => $test_vm_image['img_path']
  }

  Class['osnailyfacter::wait_for_glance_backends'] -> Glance_image<||>
}
