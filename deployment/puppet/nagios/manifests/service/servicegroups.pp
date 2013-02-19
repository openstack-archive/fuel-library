define nagios::service::servicegroups() {

#  $alias = inline_template('<%= name.capitalize -%>')

  nagios_servicegroup { $name:
    ensure => present,
#    alias  => $alias,
    target => "/etc/${nagios::params::masterdir}/${nagios::proj_name}/servicegroups.cfg",
  }
}
