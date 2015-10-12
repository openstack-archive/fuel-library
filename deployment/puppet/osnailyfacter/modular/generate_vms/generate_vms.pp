notice('MODULAR: generate_vms.pp')

$libvirt_dir = '/etc/libvirt/qemu'
$template_dir = '/var/lib/nova'
$packages = ['qemu-utils', 'qemu-kvm', 'libvirt-bin', 'xmlstarlet']
$libvirt_service_name = 'libvirtd'

$vms = hiera_array('vms_conf')

define vm_config {
  $details = $name
  $id = $details['id']

  file { "${template_dir}/template_${id}_vm.xml":
    owner   => 'root',
    group   => 'root',
    content => template('osnailyfacter/vm_libvirt.erb'),
  }
}

package { $packages:
  ensure => 'installed',
}

service { $libvirt_service_name:
  ensure  => 'running',
  require => Package[$packages],
  before  => Exec['generate_vms'],
}

file { "${libvirt_dir}/autostart":
  ensure  => 'directory',
  require => Package[$packages],
}

file { "${template_dir}":
  ensure  => 'directory',
}

vm_config { $vms:
  before  => Exec['generate_vms'],
  require => File["${template_dir}"],
}

exec { 'generate_vms':
  command     => "/usr/bin/generate_vms.sh ${libvirt_dir} ${template_dir}",
  path        => ['/usr/sbin', '/usr/bin' , '/sbin', '/bin'],
  require     => [File["${template_dir}"], File["${libvirt_dir}/autostart"]],
}
