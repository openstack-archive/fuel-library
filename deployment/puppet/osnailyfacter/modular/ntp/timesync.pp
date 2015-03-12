notice('MODULAR: timesync.pp')

$server_list = hiera('external_ntp')
$ntp_list    = regsubst($server_list['ntp_list'], ',', ' ')
#$ntp_list = hiera('master_ip')

case $operatingsystem {
  Centos: { $ntp_service = "ntpd" }
  Ubuntu: { $ntp_service = "ntp" }
}

exec { 'Show ifaces':
  command => "ip a",
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  logoutput => true,
} ->

exec { 'Show routes':
  command => "route -n",
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  logoutput => true,
} ->

exec { 'Ping name':
  command => "ping -c 4 0.pool.ntp.org",
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  logoutput => true,
} ->

exec { 'Ping IP':
  command => "ping -c 4 8.8.8.8",
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  logoutput => true,
} ->

exec { "Initial time sync":
  command => "service $ntp_service stop; killall $ntp_service; ntpdate -db $ntp_list",
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  logoutput => true,
}
