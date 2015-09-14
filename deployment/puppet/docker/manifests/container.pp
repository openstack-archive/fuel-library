class docker::container (
$tz           = 'UTC',
$yum_retries  = '5',
$yum_timeout  = '5',
$zoneinfo_dir = '/usr/share/zoneinfo',
) {

  if $tz != false {
    file { '/etc/localtime':
      ensure => present,
      target => "${zoneinfo_dir}/${tz}"
    }
  }
  file_line {'yum retries':
    path  => '/etc/yum.conf',
    line  => "retries=${yum_retries}",
    after => '\[main\]',
  }

  file_line {'yum timeout':
    path  => '/etc/yum.conf',
    line  => "timeout=${yum_timeout}",
    after => '\[main\]',
  }

}
