#
class nova::compute::libvirt (
  $libvirt_type = 'kvm',
  $vncserver_listen = '127.0.0.1',
  $libvirt_disk_cachemodes = [],
) {
  include nova::params

  if $::osfamily == 'RedHat' {

    exec { 'symlink-qemu-kvm':
      command => "/bin/ln -sf /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64",
    }

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

  if $::operatingsystem == 'Ubuntu' {

    package { 'cpufrequtils':
      ensure => present;
    }
    file { '/etc/default/cpufrequtils':
      content => "GOVERNOR=\"performance\" \n",
      require => Package['cpufrequtils'],
      notify => Service['cpufrequtils'],
    }
    service { 'cpufrequtils':
      name       => 'cpufrequtils',
      enable     => true,
      ensure     => true,
    }
    Package<| title == 'cpufrequtils'|> ~> Service<| title == 'cpufrequtils'|>
    if !defined(Service['cpufrequtils']) {
      notify{ "Module ${module_name} cannot notify service cpufrequtils\
 on package update": }
    }
  }

  if $::operatingsystem == 'Centos' {
    package { 'cpufreq-init':
      ensure => present;
    }
  }

  Service['libvirt'] -> Service['nova-compute']
  Service<| title == 'libvirt'|> ~> Service<| title == 'nova-compute'|>

  if($::nova::params::compute_package_name and $::operatingsystem=='Ubuntu') {
    package { "nova-compute-${libvirt_type}":
      ensure => present,
      before => Package[$::nova::params::compute_package_name],
    }
    Package<| title == "nova-compute-${libvirt_type}"|> ~>
    Service<| title == 'nova-compute'|>
    if !defined(Service['nova-compute']) {
      notify{ "Module ${module_name} cannot notify service nova-compute\
 on packages update": }
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
  Package<| title == 'libvirt'|> ~> Service<| title == 'libvirt'|>
  if !defined(Service['libvirt']) {
    notify{ "Module ${module_name} cannot notify service libvirt on package update": }
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
    'DEFAULT/compute_driver':      value => 'libvirt.LibvirtDriver';
    'DEFAULT/libvirt_type':        value => $libvirt_type;
    'DEFAULT/connection_type':     value => 'libvirt';
    'DEFAULT/vncserver_listen':    value => $vncserver_listen;
  }

  if size($libvirt_disk_cachemodes) > 0 {
    nova_config {
      'DEFAULT/disk_cachemodes': value => join($libvirt_disk_cachemodes, ',');
    }
  } else {
    nova_config {
      'DEFAULT/disk_cachemodes': ensure => absent;
    }
  }

  if str2bool($::is_virtual) {
    nova_config {
      'DEFAULT/libvirt_cpu_mode': value => 'none';
    }
  } else {
    nova_config {
      'DEFAULT/libvirt_cpu_mode': value => 'host-model';
    }
  }
}
