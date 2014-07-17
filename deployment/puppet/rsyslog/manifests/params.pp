class rsyslog::params {
  case $::operatingsystem {
    /(?i)(ubuntu|debian)/: {
      $rsyslog_package_name   = 'rsyslog'
      #FIXME(bogdando) enable relp package back once we include it into
      # the ISO, and if Fuel would start to use any of RELP features
      #$relp_package_name      = 'rsyslog-relp'
      $relp_package_name       = false
      $package_status         = 'installed'
      $rsyslog_d              = '/etc/rsyslog.d/'
      $rsyslog_conf           = '/etc/rsyslog.conf'
      $rsyslog_queues_dir     = '/var/lib/rsyslog'
      $rsyslog_default        = '/etc/default/rsyslog'
      $run_user               = 'syslog'
      $run_group              = 'syslog'
      $log_user               = 'syslog'
      $log_group              = 'syslog'
      $spool_dir              = '/var/spool/rsyslog/'
      $service_name           = 'rsyslog'
      $client_conf            = "${rsyslog_d}client.conf"
      $server_conf            = "${rsyslog_d}server.conf"
    }
    /(?i)(redhat|centos)/: {
      $rsyslog_package_name   = 'rsyslog'
      #FIXME(bogdando) enable relp package back once we include it into
      # the ISO, and if Fuel would start to use any of RELP features
      #$relp_package_name      = 'rsyslog-relp'
      $relp_package_name       = false
      $package_status         = 'installed'
      $rsyslog_d              = '/etc/rsyslog.d/'
      $rsyslog_conf           = '/etc/rsyslog.conf'
      $rsyslog_queues_dir     = '/var/lib/rsyslog'
      $rsyslog_default        = '/etc/default/rsyslog'
      $run_user               = 'root'
      $run_group              = 'root'
      $log_user               = 'root'
      $log_group              = 'adm'
      $spool_dir              = '/var/spool/rsyslog/'
      $service_name           = 'rsyslog'
      $client_conf            = "${rsyslog_d}client.conf"
      $server_conf            = "${rsyslog_d}server.conf"
    }
    /(?i)freebsd/: {
      $rsyslog_package_name   = 'rsyslog5'
      $relp_package_name      = 'rsyslog5-relp'
      $package_status         = 'present'
      $rsyslog_d              = '/etc/syslog.d/'
      $rsyslog_conf           = '/etc/syslog.conf'
      $rsyslog_queues_dir     = '/var/lib/rsyslog'
      $rsyslog_default        = '/etc/defaults/syslogd'
      $run_user               = 'root'
      $run_group              = 'wheel'
      $log_user               = 'root'
      $log_group              = 'wheel'
      $spool_dir              = '/var/spool/syslog/'
      $service_name           = 'syslogd'
      $client_conf            = "${rsyslog_d}client.conf"
      $server_conf            = "${rsyslog_d}server.conf"
    }


    default: {
      fail("Unsupported platform: ${::operatingsystem}")
    }
  }

}
