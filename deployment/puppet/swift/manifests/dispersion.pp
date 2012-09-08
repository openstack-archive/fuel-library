# == Class: swift::dispersion
#
# This class creates a configuration file for swift-dispersion-report and
# and swift-dispersion-populate tools.
#
# These tools need access to all the storage nodes and are generally ran
# on the swift proxy node.
#
# For more details, see :
#   http://swift.openstack.org/admin_guide.html#cluster-health
#
# === Parameters
#
# [*auth_url*]
#  String. The full URL to the authentication endpoint (eg. keystone)
#  Optional. Defaults to '127.0.0.1'.
# [*auth_user*]
#  String. The Swift username to use to run the tools.
#  Optional. Defaults to 'dispersion'.
# [*auth_tenant*]
#  String. The user's tenant/project.
#  Optional. Defaults to 'services'.
# [*auth_pass*]
#  String. The user's password.
#  Optional. Defaults to 'dispersion_password'.
# [*auth_version*]
#  String. The version to pass to the 'swift' command.
#  Use '2.0' when using Keystone.
#  Optional. Defaults to '2.0'
# [*swift_dir*]
#  String. The path to swift configuration folder
#  Optional. Defaults to '/etc/swift'.
# [*coverage*]
#  Integer. The percentage of partitions to cover.
#  Optional. Defaults to 1
# [*retries*]
#  Integer. Number of retries.
#  Optional. Defaults to 5.
# [*concurrency*]
#  Integer. Process concurrency.
#  Optional. Defaults to 25.
# [*dump_json*]
#  'yes' or 'no'. Should 'swift-dispersion-report' dump json results ?
#  Optional. Defaults to no.
#
# === Note
#
# Note: if using swift < 1.5.0, swift-dispersion-report and
# swift-dispersion-populate might need to be patched with
# https://github.com/openstack/swift/commit/9a423d0b78a105caf6011c6c3450f7d75d20b5a1
#
# === Authors
#
# François Charlier fcharlier@ploup.net
#

class swift::dispersion (
  $auth_url = 'http://127.0.0.1:5000/v2.0/',
  $auth_user = 'dispersion',
  $auth_tenant = 'services',
  $auth_pass = 'dispersion_password',
  $auth_version = '2.0',
  $swift_dir = '/etc/swift',
  $coverage = 1,
  $retries = 5,
  $concurrency = 25,
  $dump_json = 'no'
) {

  include swift::params

  file { '/etc/swift/dispersion.conf':
    ensure  => present,
    content => template('swift/dispersion.conf.erb'),
    owner   => 'swift',
    group   => 'swift',
    mode    => '0660',
    require => Package['swift'],
  }

  exec { 'swift-dispersion-populate':
    path      => ['/bin', '/usr/bin'],
    subscribe => File['/etc/swift/dispersion.conf'],
    timeout   => 0,
    onlyif    => "swift -A ${auth_url} -U ${auth_tenant}:${auth_user} -K ${auth_pass} -V ${auth_version} stat | grep 'Account: '",
    unless    => "swift -A ${auth_url} -U ${auth_tenant}:${auth_user} -K ${auth_pass} -V ${auth_version} list | grep dispersion_",
  }

}
