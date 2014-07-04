# == Class: haproxy::params
#
# This is a container class holding default parameters for for haproxy class.
#  currently, only the Redhat family is supported, but this can be easily
#  extended by changing package names and configuration file paths.
#
class haproxy::params {
  case $osfamily {
    Redhat: {
      $global_options   = {
        'log'     => "${::ipaddress} local0",
        'chroot'  => '/var/lib/haproxy',
        'pidfile' => '/var/run/haproxy.pid',
        'maxconn' => '4000',
        'user'    => 'haproxy',
        'group'   => 'haproxy',
        'daemon'  => '',
        'stats'   => 'socket /var/lib/haproxy/stats'
      }
      $defaults_options = {
        'log'     => 'global',
        'stats'   => 'enable',
        'option'  => 'redispatch',
        'retries' => '3',
        'timeout' => [
          'http-request 10s',
          'queue 1m',
          'connect 10s',
          'client 1m',
          'server 1m',
          'check 10s',
        ],
        'maxconn' => '8000'
      }
      $package_name     = 'haproxy'
      $use_include      = false
    }
    Debian: {
      $global_options   = {
        'log'     => "${::ipaddress} local0",
        'chroot'  => '/var/lib/haproxy',
        'pidfile' => '/var/run/haproxy.pid',
        'maxconn' => '4000',
        'user'    => 'haproxy',
        'group'   => 'haproxy',
        'daemon'  => '',
        'stats'   => 'socket /var/lib/haproxy/stats'
      }
      $defaults_options = {
        'log'     => 'global',
        'stats'   => 'enable',
        'option'  => 'redispatch',
        'retries' => '3',
        'timeout' => [
          'http-request 10s',
          'queue 1m',
          'connect 10s',
          'client 1m',
          'server 1m',
          'check 10s',
        ],
        'maxconn' => '8000'
      }
      $package_name     = 'haproxy'
      $use_include      = false
    }
    default: { fail("The $::osfamily operating system is not supported with the haproxy module") }
  }
  $use_stats = true
  $stats_port = '10000'
}
