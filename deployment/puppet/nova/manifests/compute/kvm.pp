class nova::compute::kvm(

) {

  nova_config {
    'libvirt_type': value  => 'kvm',
  }

  package { 'nova-compute-kvm':
    ensure => present
  }
}
