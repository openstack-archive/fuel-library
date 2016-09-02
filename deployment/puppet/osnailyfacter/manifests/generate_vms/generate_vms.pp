class osnailyfacter::generate_vms::generate_vms {

  notice('MODULAR: generate_vms/generate_vms.pp')

  $vms = hiera('vms_conf')
  $created = str2bool(inline_template('<%= @vms.all? {|x| x["created"]} %>'))

  unless $created {
    $libvirt_dir = '/etc/libvirt/qemu'
    $template_dir = '/var/lib/nova'
    $packages = ['qemu-utils', 'qemu-kvm', 'libvirt-bin', 'xmlstarlet']


    include ::nova::params

    package { $packages:
      ensure => 'installed',
    }

    service { 'libvirt-bin':
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

    $vm_config_hash = vm_config_hash($vms)
    $vm_defaults = {
      template_dir => $template_dir,
      before       => Exec['generate_vms'],
      require      => File[$template_dir],
    }
    create_resources('osnailyfacter::generate_vms::vm_config', $vm_config_hash, $vm_defaults)

    exec { 'generate_vms':
      command   => "/usr/bin/generate_vms.sh ${libvirt_dir} ${template_dir}",
      path      => ['/usr/sbin', '/usr/bin' , '/sbin', '/bin'],
      require   => [File[$template_dir], File["${libvirt_dir}/autostart"]],
      logoutput => true,
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
}
