#
# Configure ceilometer middleware for swift
#
# == Dependencies
#
# puppet-ceilometer (http://github.com/enovance/puppet-ceilometer)
#
# == Parameters
#
# [*ensure*]
#   Enable or not ceilometer fragment
#   Defaults to 'present'
#
# == Examples
#
# == Authors
#
#   Francois Charlier fcharlier@enovance.com
#
# == Copyright
#
# Copyright 2013 eNovance licensing@enovance.com
#
class swift::proxy::ceilometer(
  $ensure = 'present'
) inherits swift {

  User['swift'] {
    groups +> 'ceilometer',
  }

  if defined(Service['swift-proxy']) {
    File['/var/log/ceilometer/swift-proxy-server.log'] -> Service['swift-proxy']
  }

  file { '/var/log/ceilometer/swift-proxy-server.log':
    ensure => file,
    mode   => '0664',
    owner  => 'swift',
    group  => 'swift',
  }

  concat::fragment { 'swift_ceilometer':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/ceilometer.conf.erb'),
    order   => '33',
    require => Class['::ceilometer'],
  }

}
