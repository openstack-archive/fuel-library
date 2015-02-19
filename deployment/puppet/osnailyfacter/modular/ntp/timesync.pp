notice('MODULAR: timesync.pp')

$server_list = hiera('external_ntp')
$ntp_list    = regsubst($server_list['ntp_list'], ',', ' ')

case $operatingsystem {
  Centos: { $ntp_service = "ntpd" }
  Ubuntu: { $ntp_service = "ntp" }
}

exec { "Initial time sync":
  command => "service $ntp_service stop; killall $ntp_service; ntpdate $ntp_list",
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}
