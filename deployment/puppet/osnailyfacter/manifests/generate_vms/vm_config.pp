define osnailyfacter::generate_vms::vm_config(
  $template_dir = '/var/lib/nova',
) {
  $details = $name
  $id = $details['id']

  file { "${template_dir}/template_${id}_vm.xml":
    owner   => 'root',
    group   => 'root',
    content => template('osnailyfacter/vm_libvirt.erb'),
  }
}
