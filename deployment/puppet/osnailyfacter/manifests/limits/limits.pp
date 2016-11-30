class osnailyfacter::limits::limits {

  notice('MODULAR: limits/limits.pp')

  include ::nova::params

  $libvirt_service_name = $::nova::params::libvirt_service_name

  $roles             = hiera('roles')
  $limits            = hiera('limits', {})
  $general_mof_limit = pick($limits['general_mof_limit'], '102400')
  $libvirt_mof_limit = pick($limits['libvirt_mof_limit'], '102400')

  file { '/etc/security/limits.conf':
    ensure  => present,
    content => template('openstack/limits.conf.erb'),
    mode    => '0644',
  }

  if member($roles, 'compute') {
    file { "/etc/init/${libvirt_service_name}.override":
      ensure  => present,
      content => "limit nofile $libvirt_mof_limits $libvirt_mof_limit",
      mode    => '0644',
    }
  }
}
