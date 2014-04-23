class swift::notify::ceilometer (
  $enable_ceilometer = false,
)
{
  if $enable_ceilometer {
    concat::fragment { 'swift_ceilometer':
      target  => '/etc/swift/proxy-server.conf',
      content => template('swift/ceilometer/ceilometer.conf.erb'),
      order   => '10',
    }
  }
}
