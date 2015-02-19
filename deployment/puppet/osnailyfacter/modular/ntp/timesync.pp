notice('MODULAR: timesync.pp')

$master_ip = hiera('master_ip')

case $operatingsystem {
  Centos: { $ntp_service = "ntpd" }
  Ubuntu: { $ntp_service = "ntp" }
}

exec { "Initial time sync":
  command => "service $ntp_service stop; killall $ntp_service; ntpdate -u $master_ip && service $ntp_service start",
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}
