notice('MODULAR: timesync.pp')

$master_ip = hiera('master_ip')

exec { "Initial time sync":
  command => "NTPD=$(find /etc/init.d/ -regex \'/etc/init.d/ntp.?\'); $NTPD stop; killall ntpd; ntpdate -u $master_ip && $NTPD start",
  path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
}
