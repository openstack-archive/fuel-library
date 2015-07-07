# == Class: swift::proxy::ratelimit
#
# Configure swift ratelimit.
#
# See Swift's ratelimit documentation for more detail about the values.
#
# === Parameters
#
# [*clock_accuracy*]
#   (optional) The accuracy of swift proxy servers' clocks.
#   1000 is 1ms max difference. No rate should be higher than this.
#   Defaults to 1000
#
# [*max_sleep_time_seconds*]
#   (optional) Time before the app returns a 498 response.
#   Defaults to 60.
#
# [*log_sleep_time_seconds*]
#   (optional) if >0, enables logging of sleeps longer than
#   the value.
#   Defaults to 0.
#
# [*rate_buffer_seconds*]
#   (optional) Time in second the rate counter can skip.
#   Defaults to 5.
#
# [*account_ratelimit*]
#   (optional) if >0, limits PUT and DELETE requests to containers
#   Defaults to 0.
#
# == Dependencies
#
# == Examples
#
# == Authors
#
#   Francois Charlier fcharlier@ploup.net
#
# == Copyright
#
# Copyright 2012 eNovance licensing@enovance.com
#
class swift::proxy::ratelimit(
  $clock_accuracy = 1000,
  $max_sleep_time_seconds = 60,
  $log_sleep_time_seconds = 0,
  $rate_buffer_seconds = 5,
  $account_ratelimit = 0
) {

  concat::fragment { 'swift_ratelimit':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy/ratelimit.conf.erb'),
    order   => '26',
  }

}
