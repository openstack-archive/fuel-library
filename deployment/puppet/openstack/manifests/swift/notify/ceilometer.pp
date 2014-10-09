class openstack::swift::notify::ceilometer (
  $enable_ceilometer = false,
)
{
  if $enable_ceilometer {
    concat::fragment { 'swift_ceilometer':
      target  => '/etc/swift/proxy-server.conf',
      content => template('openstack/swift/ceilometer.conf.erb'),
      order   => '10',
    }
  }
}
