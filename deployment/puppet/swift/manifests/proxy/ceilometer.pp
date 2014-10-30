#
# Configure ceilometer middleware for swift
#
# == Dependencies
#
# puppet-ceilometer (http://github.com/enovance/puppet-ceilometer)
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

  concat::fragment { 'swift_ceilometer':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/ceilometer.conf.erb'),
    order   => '33',
    require => Class['::ceilometer']
  }

}
