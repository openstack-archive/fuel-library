define osnailyfacter::generate_vms::vm_config (
  $details,
  $template_dir = '/var/lib/nova',
) {
  file { "${template_dir}/template_${name}_vm.xml":
    owner   => 'root',
    group   => 'root',
    content => template('osnailyfacter/vm_libvirt.erb'),
  }
}
