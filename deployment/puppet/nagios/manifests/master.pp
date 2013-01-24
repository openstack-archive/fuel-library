## This is class installed nagios master
# ==Parameters
## proj_name       => isolated configuration for project
## templatehost    => checks,intervals parameters for hosts (as Hash)
# name - name of this template
# check_interval check command interval for hosts included in this group
#
## templateservice => checks,intervals parameters for services (as Hash)
# name - name of this template
# check_interval check command interval for services included in this group
#
## hostgroups      =>  create hostgroups
# Put all hostgroups from nrpe here (as Array)
class nagios::master (
$proj_name         = 'conf.d',
$hostgroups        = [],
$templatehost      = {'name' => 'default-host','check_interval' => '60'},
$templateservice   = {'name' => 'default-service' ,'check_interval'=>'60'},
$templatehost      = 'default-host',
$templateservice   = 'default-service',
$htpasswd          = {'nagiosadmin' => 'nagiosadmin'},
$contactgroups     = {'group' => 'admins', 'alias' => 'Admins'},
$contacts          = {'user' => 'hotkey', 'alias' => 'Dennis Hoppe',
                      'email' => 'nagios@%{domain}',
                      'group' => 'admins'},
) {

  validate_hash($htpasswd)
  validate_hash($templateservice)
  validate_hash($templatehost)
  validate_hash($contactgroups)
  validate_hash($contacts)

  include nagios::host
  include nagios::service
  include nagios::command
  include nagios::contact

  exec { 'external-commands':
    command => 'dpkg-statoverride --update --add nagios nagios 751 /var/lib/nagios3 && dpkg-statoverride --update --add nagios www-data 2710 /var/lib/nagios3/rw',
    path    => ['/bin','/sbin','/usr/sbin/','/usr/sbin/'],
    unless  => 'dpkg-statoverride --list nagios nagios 751 /var/lib/nagios3 && dpkg-statoverride --list nagios www-data 2710 /var/lib/nagios3/rw',
    notify  => Service['nagios3'],
  }

  # Bug: 3299
  exec { 'fix-permissions':
    command     => "chmod -R go+r /etc/nagios3/${proj_name}",
    path        => ['/bin','/sbin','/usr/sbin/','/usr/sbin/'],
    refreshonly => true,
    notify      => Service['nagios3'],
  }


  augeas {'configs':
    context => '/files/etc/nagios3/nagios.cfg',
    changes => [
      "set cfg_dir[2] \"/etc/nagios3/${proj_name}\"",
      'set check_external_commands 1',
    ],
  }

  file { '/etc/nagios3/htpasswd.users':
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('nagios/common/etc/nagios3/htpasswd.users.erb'),
    require => Package['nagios3'],
  }

  file { "/etc/nagios3/${proj_name}/templates.cfg":
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('nagios/openstack/templates.cfg.erb'),
    require => Package['nagios3'],
  }

  file { "/etc/nagios3/${proj_name}/hostgroup.cfg":
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('nagios/openstack/hostgroups.cfg.erb'),
    require => Package['nagios3'],
  }

  file { "/etc/nagios3/${proj_name}":
    recurse => true,
    owner   => root,
    group   => root,
    mode    => '0644',
    alias   => 'conf.d',
    notify  => Service['nagios3'],
    source  => 'puppet:///modules/nagios/common/etc/nagios3/conf.d',
    require => Package['nagios3'],
  }

  package { [
    'nagios3',
    'nagios-nrpe-plugin' ]:
    ensure => present,
  }

  resources { 'nagios_command':
    purge => true,
  }

  resources { 'nagios_contact':
    purge => true,
  }

  resources { 'nagios_contactgroup':
    purge => true,
  }

  resources { 'nagios_host':
    purge => true,
  }

  resources { 'nagios_hostgroup':
    purge => true,
  }

  resources { 'nagios_hostextinfo':
    purge => true,
  }

  resources { 'nagios_service':
    purge => true,
  }

  resources { 'nagios_servicegroup':
    purge => true,
  }

  service { 'nagios3':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      Augeas['configs'],
      File['conf.d'],
      Package['nagios3']
    ],
  }
}
