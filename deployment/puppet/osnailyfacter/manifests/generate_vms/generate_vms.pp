class osnailyfacter::generate_vms::generate_vms {

  notice('MODULAR: generate_vms/generate_vms.pp')

  $libvirt_dir = '/etc/libvirt/qemu'
  $template_dir = '/var/lib/nova'
  $packages = ['qemu-utils', 'qemu-kvm', 'libvirt-bin', 'xmlstarlet']

  $vms = hiera_array('vms_conf')

  include ::nova::params

  package { $packages:
    ensure => 'installed',
  }

  # TODO(skolekonov): $::nova::params::libvirt_service_name can't be used
  # directly as ubuntu naming scheme for some versions of libvirt packages
  # is used by Fuel even though os_package_type is always set to 'debian'
  if ($::operatingsystem == 'Ubuntu') and (versioncmp($::libvirt_package_version, '1.2.9.3') > 0) {
    $libvirt_service_name = 'libvirt-bin'
  } else {
    $libvirt_service_name = $::nova::params::libvirt_service_name
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

  file { $template_dir:
    ensure  => 'directory',
  }

  ::osnailyfacter::generate_vms::vm_config { $vms:
    before  => Exec['generate_vms'],
    require => File[$template_dir],
  }

  exec { 'generate_vms':
    command => "/usr/bin/generate_vms.sh ${libvirt_dir} ${template_dir}",
    path    => ['/usr/sbin', '/usr/bin' , '/sbin', '/bin'],
    require => [File[$template_dir], File["${libvirt_dir}/autostart"]],
  }

  if $::operatingsystem == 'Ubuntu' {
    # TODO(mpolenchuk): Remove when LP#1057024 has been resolved.
    # https://bugs.launchpad.net/ubuntu/+source/qemu-kvm/+bug/1057024
    file { '/dev/kvm':
      ensure => present,
      group  => 'kvm',
      mode   => '0660',
    }

    Package<||> ~> File['/dev/kvm'] -> Exec['generate_vms']
  }

}
