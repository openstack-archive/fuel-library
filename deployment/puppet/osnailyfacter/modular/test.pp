notify { 'test' :
  message => hiera('nova_report_interval'),
}
