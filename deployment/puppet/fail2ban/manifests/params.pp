class fail2ban::params {

### Application related parameters

  $package = $::operatingsystem ? {
    default => 'fail2ban',
  }

  $service = $::operatingsystem ? {
    default => 'fail2ban',
  }

  $config_dir = $::operatingsystem ? {
    default => '/etc/fail2ban',
  }

  $config_file = $::operatingsystem ? {
    default => "${config_dir}/fail2ban.local",
  }

  $jail_file = $::operatingsystem ? {
    default => "${config_dir}/jail.local",
  }

  $log_dir = $::operatingsystem ? {
    default => '/var/log/fail2ban',
  }

  $log_file = $::operatingsystem ? {
    default => "SYSLOG",
  }

  $pid_file = $::operatingsystem ? {
    /(?i:Debian|Ubuntu|Mint)/ => '/var/run/fail2ban/fail2ban.pid',
    default => '/var/run/fail2ban/fail2ban.pid',
  }

  $log_level = '3'
  $socket = '/var/run/fail2ban/fail2ban.sock'

  $ignoreip = ['127.0.0.1/8']
  $bantime = '600'
  $findtime = '600'
  $maxretry = '5'
  $backend = 'auto'
  $mailto = "hostmaster@${::domain}"
  $banaction = 'iptables-multiport'
  $mta = 'sendmail'
  $jails_protocol = 'tcp'
  $jails_chain = 'INPUT'
}
