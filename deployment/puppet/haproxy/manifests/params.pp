# == Class: haproxy::params
#
# This is a container class holding default parameters for for haproxy class.
#  currently, only the Redhat family is supported, but this can be easily
#  extended by changing package names and configuration file paths.
#
class haproxy::params {
  case $::osfamily {
    'Archlinux', 'Debian', 'RedHat': {
      $package_name     = 'haproxy'
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
      $config_file      = '/etc/haproxy/haproxy.cfg'
    }
    'FreeBSD': {
      $package_name     = 'haproxy'
      $global_options   = {
        'log'     => [
          '127.0.0.1 local0',
          '127.0.0.1 local1 notice',
        ],
        'chroot'  => '/usr/local/haproxy',
        'pidfile' => '/var/run/haproxy.pid',
        'maxconn' => '4096',
        'daemon'  => '',
      }
      $defaults_options = {
        'log'        => 'global',
        'mode'       => 'http',
        'option'     => [
          'httplog',
          'dontlognull',
        ],
        'retries'    => '3',
        'redispatch' => '',
        'maxconn'    => '2000',
        'contimeout' => '5000',
        'clitimeout' => '50000',
        'srvtimeout' => '50000',
      }
      $config_file      = '/usr/local/etc/haproxy.conf'
    }
    default: { fail("The ${::osfamily} operating system is not supported with the haproxy module") }
  }
  $use_include = false
  $use_stats = false
  $stats_port = '10000'
  $stats_ipaddresses = ['127.0.0.1']
}
