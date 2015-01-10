class { 'rsyslog::client':
  log_templates => [
    {
      name      => 'RFC3164fmt',
      template  => '<%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg%',
    },
  ],
  actionfiletemplate => 'RFC3164fmt',
}
