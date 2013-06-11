class nova::compute::libvirt (
  $libvirt_type = 'kvm',
  $vncserver_listen = '127.0.0.1'
) {

  include nova::params

  if $::osfamily == 'RedHat' {

#    yumrepo {'CentOS-Base':
#      name     => 'updates',
#      priority => 10,
#      before   => [Package['libvirt']]
#    }->
    

#    package { 'qemu':
#      ensure => present,
#    }
 
    exec { 'symlink-qemu-kvm': 
      command => "/bin/ln -sf /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64",
    } 
                   
    stdlib::safe_package {'dnsmasq-utils':}

    package { 'avahi':
      ensure => present;
    } ->

    service { 'messagebus':
      ensure => running,
      require => Package['avahi'];
    } ->

    service { 'avahi-daemon':
      ensure  => running,
      require => Package['avahi'];
    }

    Service['avahi-daemon'] -> Service['libvirt']

    service { 'libvirt-guests':
      name       => 'libvirt-guests',
      enable     => false,
      ensure     => true,
      hasstatus  => false,
      hasrestart => false,
    }

  }

  Service['libvirt'] -> Service['nova-compute']

  if($::nova::params::compute_package_name and $::operatingsystem=='Ubuntu') {
    package { "nova-compute-${libvirt_type}":
      ensure => present,
      before => Package[$::nova::params::compute_package_name],
    }
  }

  package { 'libvirt':
    name   => $::nova::params::libvirt_package_name,
    ensure => present,
  }

  file_line { 'no_qemu_selinux':
    path    => '/etc/libvirt/qemu.conf',
    line    => 'security_driver="none"',
    require => Package[$::nova::params::libvirt_package_name],
    notify  => Service['libvirt']
  }

  service { 'libvirt' :
    name     => $::nova::params::libvirt_service_name,
    ensure   => running,
    provider => $::nova::params::special_service_provider,
    require  => Package['libvirt'],
  }

  case $libvirt_type {
    'kvm': {
      package { $::nova::params::libvirt_type_kvm:
        ensure => present,
        before => Package[$::nova::params::compute_package_name],
      }
    }
  }

  nova_config {
    'DEFAULT/compute_driver':   value => 'libvirt.LibvirtDriver';
    'DEFAULT/libvirt_type':     value => $libvirt_type;
    'DEFAULT/connection_type':  value => 'libvirt';
    'DEFAULT/vncserver_listen': value => $vncserver_listen;
  }
}
