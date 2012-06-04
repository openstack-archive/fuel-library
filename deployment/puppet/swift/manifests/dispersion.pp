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
