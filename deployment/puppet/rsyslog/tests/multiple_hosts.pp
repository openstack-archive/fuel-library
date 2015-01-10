class { 'rsyslog::client':
  remote_servers => [
    {
      host       => 'logs.example.org',
    },
    {
      port       => '55514',
    },
    {
      host       => 'logs.somewhere.com',
      port       => '555',
      pattern    => '*.log',
      protocol   => 'tcp',
      format     => 'RFC3164fmt',
    },
  ]
}
