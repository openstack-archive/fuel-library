define nagios::service::servicegroups() {
  $alias = inline_template('<%= name.capitalize -%>')

  nagios_servicegroup { $name:
    ensure => present,
    alias  => $alias,
    target => '/etc/nagios3/conf.d/servicegroups.cfg',
  }
}