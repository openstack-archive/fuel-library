#
# Configure swift slo.
#
# == Examples
#
#  include swift::proxy::slo
#
# == Parameters
#
# [*max_manifest_segments*]
# Max manifest segments.
# Default to 1000.
#
# [*max_manifest_size*]
# Max manifest size.
# Default to 2097152.
#
# [*min_segment_size*]
# minimal segment size
# Default to 1048576.
#
# [*rate_limit_after_segment*]
# Start rate-limiting SLO segment serving after the Nth segment of a segmented object.
# Default to 10.
#
# [*rate_limit_segments_per_sec*]
# Once segment rate-limiting kicks in for an object, limit segments served to N per second.
# 0 means no rate-limiting.
# Default to 0.
#
# [*max_get_time*]
# Time limit on GET requests (seconds).
# Default to 86400.
#
# == Authors
#
#   Xingchao Yu  yuxcer@gmail.com
#
# == Copyright
#
# Copyright 2014 UnitedStack licensing@unitedstack.com
#
class swift::proxy::slo (
  $max_manifest_segments       = '1000',
  $max_manifest_size           = '2097152',
  $min_segment_size            = '1048576',
  $rate_limit_after_segment    = '10',
  $rate_limit_segments_per_sec = '0',
  $max_get_time                = '86400'
) {

  concat::fragment { 'swift_slo':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/slo.conf.erb'),
    order   => '35',
  }

}
