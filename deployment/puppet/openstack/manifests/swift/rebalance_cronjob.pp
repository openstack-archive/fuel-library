# == Class: openstack::swift::rebalance_cronjob
#
# Creates cronjobs to rebalance and re-push swift rings
#
# === Parameters
#
#  [*master_swift_proxy_ip*]
#    (required) IP of swift proxy master
#
#  [*primary_proxy*]
#    (optional) Is it a primary proxy?
#    Defaults to false.
#
#  [*rings*]
#    (optional) Array of swift rings.
#    Defaults to ['account', 'object', 'container']
#
#  [*ring_rebalance_period*]
#    (optional) Defines the ammount of hours between cronjob runs.
#    Defaults to 23
#

class openstack::swift::rebalance_cronjob(
  $master_swift_proxy_ip,
  $primary_proxy         = false,
  $rings                 = ['account', 'object', 'container'],
  $ring_rebalance_period = 23,
) {

  # setup a cronjob to rebalance rings periodically on primary
  file { '/usr/local/bin/swift-rings-rebalance.sh':
    ensure  => $primary_proxy ? {
      true    => file,
      default => absent,
    },
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('openstack/swift/swift-rings-rebalance.sh.erb'),
  }
  cron { 'swift-rings-rebalance':
    ensure  => $primary_proxy ? {
      true    => present,
      default => absent,
    },
    command => '/usr/local/bin/swift-rings-rebalance.sh &>/dev/null',
    user    => 'swift',
    hour    => "*/$ring_rebalance_period",
    minute  => '15',
  }

  # setup a cronjob to download rings periodically on secondaries
  file { '/usr/local/bin/swift-rings-sync.sh':
    ensure  => $primary_proxy ? {
      true    => absent,
      default => file,
    },
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    content => template('openstack/swift/swift-rings-sync.sh.erb'),
  }
  cron { 'swift-rings-sync':
    ensure  => $primary_proxy ? {
      true    => absent,
      default => present,
    },
    command => '/usr/local/bin/swift-rings-sync.sh &>/dev/null',
    user    => 'swift',
    hour    => "*/$ring_rebalance_period",
    minute  => '25',
  }
}
