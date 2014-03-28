# Configure and run rsyslogd server

class {"::rsyslog::server":
  enable_tcp => true,
  enable_udp => true,
  server_dir => '/var/log/',
  port       => 514,
  high_precision_timestamps => true,
  virtual    => str2bool($::is_virtual),
}

