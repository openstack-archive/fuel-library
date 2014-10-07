class docker::container (
$tz           = 'UTC',
$zoneinfo_dir = '/usr/share/zoneinfo',
) {

  if $tz != false {
    file { '/etc/localtime':
      ensure => present,
      target => "${zoneinfo_dir}/${tz}"
    }
  }

}
