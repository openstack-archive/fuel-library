#
# Configure swift dlo.
#
# == Examples
#
#  include ::swift::proxy::dlo
#
# == Parameters
#
# [*rate_limit_after_segment*]
# Start rate-limiting DLO segment serving after the Nth segment of a segmented object.
# Default to 10.
#
# [*rate_limit_segments_per_sec*]
# Once segment rate-limiting kicks in for an object, limit segments served to N per second.
# 0 means no rate-limiting.
# Default to 1.
#
# [*max_get_time*]
# Time limit on GET requests (seconds).
# Default to 86400.
#
# == Authors
#
#   Aleksandr Didenko adidenko@mirantis.com
#
# == Copyright
#
# Copyright 2015 Mirantis Inc, unless otherwise noted.
#
class swift::proxy::dlo (
  $rate_limit_after_segment    = '10',
  $rate_limit_segments_per_sec = '1',
  $max_get_time                = '86400'
) {

  concat::fragment { 'swift_dlo':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/dlo.conf.erb'),
    order   => '36',
  }

}
