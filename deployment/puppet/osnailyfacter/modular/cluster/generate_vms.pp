$libvirt_dir = '/etc/libvirt/qemu'
$template_dir = '/var/lib/vms'
$packages = ['qemu-utils', 'qemu-kvm', 'libvirt-bin', 'xmlstarlet']
$libvirt_service_name = 'libvirt-bin'

package { $packages:
  ensure => 'installed',
}
service { $libvirt_service_name:
  ensure  => 'running',
  require => Package[$packages],
}
file { "${libvirt_dir}/autostart":
  ensure  => 'directory',
  require => Package[$packages],
}
exec { 'generate_vms':
  command => "/etc/puppet/modules/osnailyfacter/modular/cluster/generate_vms.sh ${libvirt_dir} ${template_dir}",
  onlyif  => "test `virsh -q list | wc -l` -lt 1",
  path    => ['/usr/sbin', '/usr/bin' , '/sbin', '/bin'],
  notify  => Service[$libvirt_service_name],
  require => Package[$packages],
}
